import axiosInstance, { aiAxiosInstance } from "./axiosInstance";

export const movmentPlusApi = {
  getGalleryByToken: async (token) => {
    const response = await axiosInstance.get(`/gallery/${token}`);
    return response.data;
  },

  uploadFile: async (token, collectionName, file) => {
    const formData = new FormData();
    formData.append("file", file);
    formData.append("collection", collectionName);

    // Placeholder endpoint - verify with backend team
    const response = await axiosInstance.post(
      `/gallery/${token}/upload`,
      formData,
      {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      },
    );
    return response.data;
  },

  /**
   * Send the guest's selfie to the AI service (happywedzai / samaroai), which
   * stores it against the event the gallery token belongs to. Matching happens
   * separately, in getMyPhotos.
   *
   * The service identifies the guest from an X-User-ID header rather than the
   * app's JWT, so the logged-in user's id has to be passed explicitly.
   */
  uploadSelfie: async ({ token, file, userId }) => {
    const formData = new FormData();
    formData.append("image", file);
    formData.append("token", token);

    const response = await aiAxiosInstance.post("/events/selfie", formData, {
      headers: {
        "Content-Type": "multipart/form-data",
        "X-User-ID": String(userId),
      },
      // Nothing here needs cookies — the guest is identified by the X-User-ID
      // header — and sending them makes the browser demand
      // Access-Control-Allow-Credentials on the preflight.
      withCredentials: false,
      // Uploading a phone-sized photo and forwarding it to S3 regularly beats
      // the shared instance's 30s default.
      timeout: 120000,
    });
    return response.data;
  },

  /**
   * Match the guest's most recent selfie for this event against every encoded
   * face in the gallery.
   *
   * Returns { matches: [{ photo_id, photo_url, function_name, distance }],
   * count, threshold, message? }. An empty matches array is a normal answer —
   * `message` says whether no selfie was uploaded, no face was detected in it,
   * the photos have not been encoded yet, or nobody matched.
   *
   * Face encoding runs in the background after a vendor uploads, so a gallery
   * queried moments after an upload can legitimately return zero matches.
   */
  getMyPhotos: async ({ token, userId }) => {
    const response = await aiAxiosInstance.get("/events/my-photos", {
      params: { token },
      headers: { "X-User-ID": String(userId) },
      // See uploadSelfie.
      withCredentials: false,
      // This call downloads the selfie back from S3 and runs dlib's CNN face
      // detector over it before comparing embeddings — measured at ~78s on CPU
      // for one selfie against 26 stored faces. The shared instance's 30s
      // default cut it off long before it could answer.
      timeout: 240000,
    });
    return response.data;
  },
};
