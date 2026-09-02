// const API_BASE_URL =
//   import.meta.env.VITE_API_BASE_URL ||
//   (import.meta.env.DEV ? "/ai" : "https://www.happywedz.com/ai");

// class BeautyApiService {
//   constructor() {
//     this.baseURL = API_BASE_URL.replace(/\/+$/, "");
//   }

//   buildUrl(path) {
//     const cleanPath = path.replace(/^\/+/, "");
//     return `${this.baseURL}/${cleanPath}`;
//   }

//   async makeJsonRequest(path, options = {}) {
//     const url = this.buildUrl(path);

//     const defaultOptions = {
//       headers: {
//         "Content-Type": "application/json",
//         Accept: "application/json",
//       },
//     };

//     const { signal, ...rest } = options;
//     const config = {
//       ...defaultOptions,
//       ...rest,
//       signal,
//       headers: {
//         ...defaultOptions.headers,
//         ...(rest.headers || {}),
//       },
//     };

//     const response = await fetch(url, config);

//     if (!response.ok) {
//       const text = await response.text().catch(() => "");
//       throw new Error(
//         `HTTP ${response.status}: ${text || response.statusText}`
//       );
//     }

//     return response.json().catch(() => ({}));
//   }

//   async makeFormRequest(path, formData, options = {}) {
//     const url = this.buildUrl(path);

//     const { signal, ...rest } = options;
//     const config = {
//       method: "POST",
//       body: formData,
//       signal,
//       ...rest,
//       headers: {
//         Accept: "application/json",
//         ...(rest.headers || {}),
//       },
//     };

//     const response = await fetch(url, config);

//     if (!response.ok) {
//       const text = await response.text().catch(() => "");
//       throw new Error(
//         `HTTP ${response.status}: ${text || response.statusText}`
//       );
//     }

//     return response.json().catch(() => ({}));
//   }

//   async getFilteredProducts(category, detailedCategory) {
//     const qs = new URLSearchParams();

//     const userInfo = JSON.parse(localStorage.getItem("userInfo"));
//     const role = userInfo?.role;

//     if (category) qs.set("category", category);
//     if (detailedCategory) qs.set("detailed_category", detailedCategory);
//     if (role) qs.set("user", role);

//     return this.makeJsonRequest(`/products/filter_products?${qs.toString()}`, {
//       method: "GET",
//     });
//   }

//   async uploadImage(file, imageType = "ORIGINAL", signal) {
//     const form = new FormData();
//     form.append("image", file);
//     form.append("file", file);
//     form.append("image_type", imageType);

//     return this.makeFormRequest("/images", form, { signal });
//   }

//   async applyMakeup(payload, signal) {
//     return this.makeJsonRequest("/images/apply-makeup", {
//       method: "POST",
//       body: JSON.stringify(payload),
//       signal,
//     });
//   }

//   async getImageById(imageId, signal) {
//     return this.makeJsonRequest(`/images/${imageId}`, {
//       method: "GET",
//       signal,
//     });
//   }
// }

// export const beautyApi = new BeautyApiService();
// export { BeautyApiService };

// Set VITE_BEAUTY_API_BASE_URL in .env to point at a local AI service.
// Falls back to production when unset (e.g. deployed builds).
const BEAUTY_API_BASE_URL = (
  import.meta.env.VITE_BEAUTY_API_BASE_URL || "https://www.happywedz.com/ai/api"
).replace(/\/+$/, "");

// The upload API rejects files above 1 MB. Instead of blocking the user, shrink
// any image below that ceiling before sending it, so photos of any size work.
const UPLOAD_SIZE_LIMIT = 950 * 1024;

const loadImage = (file) =>
  new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve(img);
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("Could not read the selected image"));
    };
    img.src = url;
  });

const canvasToBlob = (canvas, quality) =>
  new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg", quality));

export const compressImage = async (file) => {
  if (!file || !file.type?.startsWith("image/")) return file;
  if (file.size <= UPLOAD_SIZE_LIMIT) return file;

  try {
    const img = await loadImage(file);
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");

    // Step the image down until it fits: first shrink dimensions, then quality.
    let maxDim = 2048;
    for (let attempt = 0; attempt < 8; attempt++) {
      const scale = Math.min(1, maxDim / Math.max(img.width, img.height));
      canvas.width = Math.max(1, Math.round(img.width * scale));
      canvas.height = Math.max(1, Math.round(img.height * scale));
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

      for (const quality of [0.85, 0.7, 0.55]) {
        const blob = await canvasToBlob(canvas, quality);
        if (blob && blob.size <= UPLOAD_SIZE_LIMIT) {
          const name = file.name.replace(/\.[^.]+$/, "") || "photo";
          return new File([blob], `${name}.jpg`, {
            type: "image/jpeg",
            lastModified: file.lastModified,
          });
        }
      }
      maxDim = Math.round(maxDim * 0.75);
    }
    return file;
  } catch {
    return file;
  }
};

class BeautyApiService {
  async makeJsonRequest(path, options = {}) {
    const { signal, ...rest } = options;
    const url = `${BEAUTY_API_BASE_URL}${path.startsWith("/") ? path : `/${path}`}`;
    const response = await fetch(url, {
      method: rest.method || "GET",
      body: rest.body,
      signal,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        ...(rest.headers || {}),
      },
    });
    if (!response.ok) {
      const text = await response.text().catch(() => "");
      throw new Error(
        `HTTP ${response.status}: ${text || response.statusText}`,
      );
    }
    return response.json().catch(() => ({}));
  }

  async makeFormRequest(path, formData, options = {}) {
    const { signal, ...rest } = options;
    const url = `${BEAUTY_API_BASE_URL}${path.startsWith("/") ? path : `/${path}`}`;
    const response = await fetch(url, {
      method: "POST",
      body: formData,
      signal,
      headers: {
        Accept: "application/json",
        ...(rest.headers || {}),
      },
    });
    if (!response.ok) {
      const text = await response.text().catch(() => "");
      throw new Error(
        `HTTP ${response.status}: ${text || response.statusText}`,
      );
    }
    return response.json().catch(() => ({}));
  }

  async getFilteredProducts(category, detailedCategory) {
    const qs = new URLSearchParams();

    const userInfo = JSON.parse(localStorage.getItem("userInfo"));
    const role = userInfo?.role;

    if (category) qs.set("category", category);
    if (detailedCategory) qs.set("detailed_category", detailedCategory);
    if (role) qs.set("user", role);

    return this.makeJsonRequest(`/products/filter_products?${qs.toString()}`);
  }

  async uploadImage(file, imageType = "ORIGINAL", signal) {
    const upload = await compressImage(file);

    const form = new FormData();
    form.append("image", upload);
    form.append("file", upload);
    form.append("image_type", imageType);

    return this.makeFormRequest("/images", form, { signal });
  }

  async applyMakeup(payload, signal) {
    let finalPayload = payload;
    try {
      const userInfo = JSON.parse(localStorage.getItem("userInfo")) || {};
      if (userInfo.role) {
        finalPayload = { ...payload, user: userInfo.role };
      }
    } catch {}

    return this.makeJsonRequest("/images/apply-makeup", {
      method: "POST",
      body: JSON.stringify(finalPayload),
      signal,
    });
  }

  // Direct <img src> for an uploaded/rendered image. Must be built off the
  // beauty base URL — VITE_API_BASE_URL points at the Node backend, which does
  // not serve /images/:id.
  getImageUrl(imageId) {
    return `${BEAUTY_API_BASE_URL}/images/${imageId}`;
  }

  async getImageById(imageId, signal) {
    return this.makeJsonRequest(`/images/${imageId}`, {
      method: "GET",
      signal,
    });
  }
}

export const beautyApi = new BeautyApiService();
export { BeautyApiService };
