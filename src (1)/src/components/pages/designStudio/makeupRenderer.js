import * as faceapi from "face-api.js";

/**
 * Client-side virtual makeup rendering.
 *
 * The AI service's /images/apply-makeup does this server-side with a Python CV
 * pipeline. This renders the same set of products in the browser instead, from
 * the 68-point face landmarks that face-api.js already ships in /public/models,
 * so the try-on works without that service and without a network round trip per
 * shade change.
 *
 * Each product becomes one soft-masked layer composited over the photo. The
 * blend modes matter: multiply keeps the skin's own shading and highlights
 * visible through colour, which is what makes lipstick and blush read as makeup
 * rather than as flat paint.
 */

const MODEL_URL = "/models";

// Above this, TinyFaceDetector's box is good enough to skip the heavy model.
const TINY_TRUSTED = 0.75;
// Below this, even SSD's box is too doubtful to paint from.
const SSD_USABLE = 0.3;

let modelsPromise = null;
let ssdPromise = null;

export function loadMakeupModels() {
    if (!modelsPromise) {
        modelsPromise = (async () => {
            await faceapi.nets.tinyFaceDetector.loadFromUri(MODEL_URL);
            await faceapi.nets.faceLandmark68Net.loadFromUri(MODEL_URL);
        })().catch((err) => {
            // Let a later attempt retry rather than caching the failure.
            modelsPromise = null;
            throw err;
        });
    }
    return modelsPromise;
}

/**
 * The heavier detector, loaded only when the fast one finds nothing. It costs
 * more to download but copes with the tightly cropped close-ups people actually
 * upload, which TinyFaceDetector regularly misses.
 */
function loadSsd() {
    if (!ssdPromise) {
        ssdPromise = faceapi.nets.ssdMobilenetv1.loadFromUri(MODEL_URL).catch((err) => {
            ssdPromise = null;
            throw err;
        });
    }
    return ssdPromise;
}

/**
 * Landmark detection is the expensive step and the photo never changes while
 * the user tries shades, so the face is detected once per image.
 */
const faceCache = new Map();

async function loadBitmap(imageUrl) {
    // Fetched as bytes rather than assigned to img.src: a blob is same-origin,
    // so the canvas stays readable even though the API is on another port.
    const res = await fetch(imageUrl, { mode: "cors" });
    if (!res.ok) throw new Error(`Could not load the photo (HTTP ${res.status})`);
    return createImageBitmap(await res.blob());
}

/** Draw the photo onto a larger canvas with empty margin around it. */
function padded(bitmap, pad) {
    const canvas = document.createElement("canvas");
    canvas.width = bitmap.width + pad * 2;
    canvas.height = bitmap.height + pad * 2;
    const ctx = canvas.getContext("2d");
    ctx.fillStyle = "#808080";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(bitmap, pad, pad);
    return canvas;
}

async function getFace(imageUrl) {
    if (faceCache.has(imageUrl)) return faceCache.get(imageUrl);

    await loadMakeupModels();
    const bitmap = await loadBitmap(imageUrl);

    const plain = document.createElement("canvas");
    plain.width = bitmap.width;
    plain.height = bitmap.height;
    plain.getContext("2d").drawImage(bitmap, 0, 0);

    // Close-up crops where the face runs past the frame detect better with
    // margin added, so each detector also gets a padded attempt; the offset is
    // subtracted afterwards to bring landmarks back to image coordinates.
    const pad = Math.round(Math.max(bitmap.width, bitmap.height) * 0.3);
    const padCanvas = padded(bitmap, pad);

    // A weak detection still yields 68 landmarks — they just sit in the wrong
    // place, which paints lipstick on a chin. So candidates are ranked by score
    // and a low-scoring one is never trusted just for arriving first.
    let best = null;
    const consider = (found, offset) => {
        if (!found) return;
        const score = found.detection.score;
        if (!best || score > best.score) best = { found, offset, score };
    };

    const tiny = new faceapi.TinyFaceDetectorOptions({ inputSize: 608, scoreThreshold: 0.25 });
    consider(await faceapi.detectSingleFace(plain, tiny).withFaceLandmarks(), 0);
    if (!best || best.score < TINY_TRUSTED) {
        consider(await faceapi.detectSingleFace(padCanvas, tiny).withFaceLandmarks(), pad);
    }

    // The fast detector is unreliable on tight crops (it scored 0.32 on a photo
    // SSD read at 0.95), so anything short of confident goes to the big model.
    if (!best || best.score < TINY_TRUSTED) {
        await loadSsd();
        const ssd = new faceapi.SsdMobilenetv1Options({ minConfidence: 0.2 });
        const ssdBest = { value: null };
        for (const [canvas, offset] of [
            [plain, 0],
            [padCanvas, pad],
        ]) {
            const found = await faceapi.detectSingleFace(canvas, ssd).withFaceLandmarks();
            if (found && (!ssdBest.value || found.detection.score > ssdBest.value.found.detection.score)) {
                ssdBest.value = { found, offset };
            }
        }
        if (ssdBest.value && ssdBest.value.found.detection.score >= SSD_USABLE) {
            best = {
                found: ssdBest.value.found,
                offset: ssdBest.value.offset,
                score: ssdBest.value.found.detection.score,
            };
        }
    }

    if (!best) {
        throw new Error(
            "No face detected in this photo. Please upload a clear, front-facing photo."
        );
    }

    const detection = best.found;
    const offset = best.offset;

    const entry = {
        bitmap,
        points: detection.landmarks.positions.map((p) => ({
            x: p.x - offset,
            y: p.y - offset,
        })),
    };
    faceCache.set(imageUrl, entry);
    return entry;
}

export function forgetFace(imageUrl) {
    faceCache.delete(imageUrl);
}

// --- landmark regions (standard 68-point layout) -------------------------

const JAW = range(0, 16);
const BROW_L = range(17, 21);
const BROW_R = range(22, 26);
const NOSE_BOTTOM = range(31, 35);
const EYE_L = range(36, 41);
const EYE_R = range(42, 47);
const LIPS_OUTER = range(48, 59);
const LIPS_INNER = range(60, 67);
const LID_UPPER_L = [36, 37, 38, 39];
const LID_LOWER_L = [39, 40, 41, 36];
const LID_UPPER_R = [42, 43, 44, 45];
const LID_LOWER_R = [45, 46, 47, 42];

function range(a, b) {
    const out = [];
    for (let i = a; i <= b; i++) out.push(i);
    return out;
}

const at = (pts, idx) => idx.map((i) => pts[i]);
const mid = (a, b) => ({ x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 });
const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);

function centroid(points) {
    const sum = points.reduce((acc, p) => ({ x: acc.x + p.x, y: acc.y + p.y }), { x: 0, y: 0 });
    return { x: sum.x / points.length, y: sum.y / points.length };
}

/** Every size below is expressed against face width, so any photo resolution works. */
function metrics(pts) {
    const faceWidth = dist(pts[0], pts[16]);
    const browY = Math.min(...at(pts, [...BROW_L, ...BROW_R]).map((p) => p.y));
    const chinY = pts[8].y;
    return { faceWidth, browY, chinY, faceHeight: chinY - browY };
}

// --- drawing helpers ----------------------------------------------------

function scratchFor(base) {
    const c = document.createElement("canvas");
    c.width = base.width;
    c.height = base.height;
    return c;
}

function tracePolygon(ctx, points, close = true) {
    ctx.moveTo(points[0].x, points[0].y);
    for (let i = 1; i < points.length; i++) ctx.lineTo(points[i].x, points[i].y);
    if (close) ctx.closePath();
}

/** Feathered edges are what keep a mask from looking like a sticker. */
function paint(base, blend, alpha, blurPx, drawFn) {
    if (alpha <= 0) return;
    const scratch = scratchFor(base);
    const sctx = scratch.getContext("2d");
    if (blurPx > 0) sctx.filter = `blur(${blurPx}px)`;
    drawFn(sctx);
    sctx.filter = "none";

    const bctx = base.getContext("2d");
    bctx.save();
    bctx.globalCompositeOperation = blend;
    bctx.globalAlpha = Math.min(1, alpha);
    bctx.drawImage(scratch, 0, 0);
    bctx.restore();
}

function fillRegion(base, points, color, { blend, alpha, blur, holes }) {
    paint(base, blend, alpha, blur, (ctx) => {
        ctx.fillStyle = color;
        ctx.beginPath();
        tracePolygon(ctx, points);
        if (holes) holes.forEach((h) => tracePolygon(ctx, h));
        ctx.fill("evenodd");
    });
}

function strokeLine(base, points, color, { blend, alpha, blur, width, wing = 0 }) {
    paint(base, blend, alpha, blur, (ctx) => {
        ctx.strokeStyle = color;
        ctx.lineWidth = width;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        tracePolygon(ctx, points, false);
        if (wing) {
            // Flick past the outer corner, following the lash line's direction.
            const a = points[points.length - 2];
            const b = points[points.length - 1];
            const len = dist(a, b) || 1;
            ctx.lineTo(b.x + ((b.x - a.x) / len) * wing, b.y + ((b.y - a.y) / len) * wing - wing * 0.5);
        }
        ctx.stroke();
    });
}

function fillEllipse(base, cx, cy, rx, ry, color, { blend, alpha, blur, gradient }) {
    paint(base, blend, alpha, blur, (ctx) => {
        if (gradient) {
            const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, Math.max(rx, ry));
            g.addColorStop(0, "rgba(0,0,0,0)");
            g.addColorStop(0.45, color);
            g.addColorStop(1, color);
            ctx.fillStyle = g;
        } else {
            ctx.fillStyle = color;
        }
        ctx.beginPath();
        ctx.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2);
        ctx.fill();
    });
}

/**
 * Widen a lid outline away from the eye to make a shadow/lash area, pushing the
 * points towards the brow (for upper lids) or the cheek (for lower lids).
 */
function expandFromEye(pts, lidIdx, eyeIdx, amount) {
    const eyeCentre = centroid(at(pts, eyeIdx));
    return at(pts, lidIdx).map((p) => {
        const dx = p.x - eyeCentre.x;
        const dy = p.y - eyeCentre.y;
        const len = Math.hypot(dx, dy) || 1;
        return { x: p.x + (dx / len) * amount, y: p.y + (dy / len) * amount };
    });
}

// --- per-product layers -------------------------------------------------

const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

/**
 * Intensities come from the product sliders and are not on one scale — bindi is
 * a size in the 1-10 range, eyeshadow goes past 1, the rest sit near 0-1 — so
 * each layer maps its own value into something sane.
 */
const LAYERS = {
    foundation(base, pts, m, color, i) {
        // Face polygon: jaw plus an estimated forehead above the brows.
        const lift = m.faceHeight * 0.42;
        const forehead = at(pts, [...BROW_R].reverse().concat([...BROW_L].reverse())).map((p) => ({
            x: p.x,
            y: p.y - lift,
        }));
        fillRegion(base, [...at(pts, JAW), ...forehead], color, {
            blend: "soft-light",
            alpha: clamp(i, 0, 1) * 0.75,
            blur: m.faceWidth * 0.05,
        });
    },

    concealer(base, pts, m, color, i) {
        const alpha = clamp(i, 0, 1) * 0.45;
        [
            [EYE_L, LID_LOWER_L],
            [EYE_R, LID_LOWER_R],
        ].forEach(([eye]) => {
            const c = centroid(at(pts, eye));
            const w = dist(pts[eye[0]], pts[eye[3]]);
            fillEllipse(base, c.x, c.y + w * 0.45, w * 0.55, w * 0.3, color, {
                blend: "soft-light",
                alpha,
                blur: m.faceWidth * 0.035,
            });
        });
    },

    contour(base, pts, m, color, i) {
        const alpha = clamp(i, 0, 1) * 0.5;
        const width = m.faceWidth * 0.075;
        const blur = m.faceWidth * 0.05;
        strokeLine(base, at(pts, [1, 2, 3, 4]), color, { blend: "multiply", alpha, blur, width });
        strokeLine(base, at(pts, [15, 14, 13, 12]), color, { blend: "multiply", alpha, blur, width });
    },

    blush(base, pts, m, color, i) {
        const alpha = clamp(i, 0, 1) * 0.55;
        const r = m.faceWidth * 0.15;
        // Cheek apex: out towards the jaw from the nostril, lifted under the eye.
        [
            [pts[3], pts[31], pts[36]],
            [pts[13], pts[35], pts[45]],
        ].forEach(([jaw, nostril, eye]) => {
            const c = mid(mid(jaw, nostril), { x: nostril.x, y: eye.y });
            fillEllipse(base, c.x, c.y, r, r * 0.72, color, {
                blend: "multiply",
                alpha,
                blur: m.faceWidth * 0.07,
            });
        });
    },

    eyeshadow(base, pts, m, color, i) {
        const alpha = clamp(i / 1.5, 0, 1) * 0.7;
        const lift = m.faceWidth * 0.075;
        [
            [LID_UPPER_L, EYE_L],
            [LID_UPPER_R, EYE_R],
        ].forEach(([lid, eye]) => {
            const outer = expandFromEye(pts, lid, eye, lift);
            fillRegion(base, [...at(pts, lid), ...outer.reverse()], color, {
                blend: "multiply",
                alpha,
                blur: m.faceWidth * 0.03,
            });
        });
    },

    eyeliner(base, pts, m, color, i) {
        const alpha = clamp(i, 0, 1) * 0.95;
        const width = m.faceWidth * 0.011;
        [
            [LID_UPPER_L, m.faceWidth * 0.03],
            [LID_UPPER_R, m.faceWidth * 0.03],
        ].forEach(([lid, wing], idx) => {
            const line = at(pts, idx === 0 ? [...lid].reverse() : lid);
            strokeLine(base, line, color, {
                blend: "source-over",
                alpha,
                blur: m.faceWidth * 0.004,
                width,
                wing,
            });
        });
    },

    kajal(base, pts, m, color, i) {
        const alpha = clamp(i, 0, 1) * 0.85;
        const width = m.faceWidth * 0.009;
        [LID_LOWER_L, LID_LOWER_R].forEach((lid) => {
            strokeLine(base, at(pts, lid), color, {
                blend: "source-over",
                alpha,
                blur: m.faceWidth * 0.005,
                width,
            });
        });
    },

    mascara(base, pts, m, color, i) {
        const alpha = clamp(i, 0, 1) * 0.7;
        // Lashes read as a soft dark band just outside the upper lid.
        [
            [LID_UPPER_L, EYE_L],
            [LID_UPPER_R, EYE_R],
        ].forEach(([lid, eye]) => {
            const outer = expandFromEye(pts, lid, eye, m.faceWidth * 0.018);
            strokeLine(base, outer, color, {
                blend: "source-over",
                alpha,
                blur: m.faceWidth * 0.008,
                width: m.faceWidth * 0.016,
            });
        });
    },

    lipstick(base, pts, m, color, i) {
        // evenodd with the inner lip as a hole keeps the mouth opening clear.
        fillRegion(base, at(pts, LIPS_OUTER), color, {
            blend: "multiply",
            alpha: clamp(i, 0, 1) * 0.9,
            blur: m.faceWidth * 0.008,
            holes: [at(pts, LIPS_INNER)],
        });
    },

    contactlenses(base, pts, m, color, i) {
        // Intensity defaults low for lenses; keep a floor so the colour shows.
        const alpha = clamp(0.35 + i, 0, 1) * 0.8;
        [EYE_L, EYE_R].forEach((eye) => {
            const c = centroid(at(pts, eye));
            const r = dist(pts[eye[0]], pts[eye[3]]) * 0.23;
            fillEllipse(base, c.x, c.y, r, r, color, {
                blend: "source-over",
                alpha,
                blur: r * 0.25,
                gradient: true,
            });
        });
    },

    bindi(base, pts, m, color, i) {
        // Here the slider is a size, not an opacity.
        const r = m.faceWidth * 0.012 * clamp(i, 1, 10) * 0.5;
        const brows = mid(pts[21], pts[22]);
        fillEllipse(base, brows.x, brows.y - r * 0.4, r, r, color, {
            blend: "source-over",
            alpha: 1,
            blur: r * 0.12,
        });
    },
};

/** Painted in this order so skin goes down first and liner/lashes sit on top. */
const LAYER_ORDER = [
    "foundation",
    "concealer",
    "contour",
    "blush",
    "eyeshadow",
    "mascara",
    "eyeliner",
    "kajal",
    "lipstick",
    "contactlenses",
    "bindi",
];

/**
 * Render a look and return an object URL for the result.
 *
 * layers: [{ category, colorHex, intensity }] — category matches the product's
 * detailed category name, lowercased, exactly as FiltersPage tracks it.
 */
export async function renderLook({ imageUrl, layers }) {
    const { bitmap, points } = await getFace(imageUrl);

    const base = document.createElement("canvas");
    base.width = bitmap.width;
    base.height = bitmap.height;
    base.getContext("2d").drawImage(bitmap, 0, 0);

    const m = metrics(points);
    const byCategory = new Map(layers.map((l) => [l.category, l]));

    for (const category of LAYER_ORDER) {
        const layer = byCategory.get(category);
        if (!layer || !layer.colorHex) continue;
        LAYERS[category](base, points, m, layer.colorHex, Number(layer.intensity) || 0);
    }

    const blob = await new Promise((resolve) => base.toBlob(resolve, "image/jpeg", 0.92));
    if (!blob) throw new Error("Could not render the look. Please try again.");
    return URL.createObjectURL(blob);
}
