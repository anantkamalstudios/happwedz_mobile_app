export const TEMPLATE_LIST = [
  {
    id: "royal",
    name: "Royal Theme",
    previewImage: "./images/web-previews/index.png",
    description: "Elegant gold and white wedding theme.",
    load: () => import("./royal/index"),
  },
  {
    id: "floral",
    name: "Floral Theme",
    previewImage: "./images/web-previews/floral1.png",
    description: "Soft romantic floral design.",
    load: () => import("./floral/index"),
  },
  {
    id: "modern",
    name: "Modern Theme",
    previewImage: "./images/web-previews/mordern.png",
    description: "Modern and sleek design.",
    // load: () => import("./modern/index"),
    load: () => import("./modern/index"),
  },
];
