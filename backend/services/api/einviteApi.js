const API_BASE_URL = "https://happywedz.com/api";

// Helper to get auth headers
const getAuthHeaders = () => {
  const token = localStorage.getItem("token");
  return {
    "Content-Type": "application/json",
    Accept: "application/json",
    ...(token && { Authorization: `Bearer ${token}` }),
  };
};

export const einviteApi = {
  createInstance: async (payload) => {
    try {
      const response = await fetch(`${API_BASE_URL}/einvites/cards/instances`, {
        method: "POST",
        headers: getAuthHeaders(),
        body: JSON.stringify(payload),
      });
      if (!response.ok) {
        let body;
        try {
          body = await response.json();
          console.error("API Error response:", {
            status: response.status,
            statusText: response.statusText,
            url: `${API_BASE_URL}/einvites/cards/instances`,
            requestBody: payload,
            responseBody: body,
          });
        } catch (e) {
          body = await response.text();
          console.error("Failed to parse API response:", {
            status: response.status,
            statusText: response.statusText,
            url: `${API_BASE_URL}/einvites/cards/instances`,
            requestBody: payload,
            responseBody: body,
          });
        }
        throw new Error(
          typeof body === "string"
            ? body
            : body?.message || "Failed to create instance"
        );
      }
      return await response.json();
    } catch (error) {
      console.error("Error creating instance:", error);
      throw error;
    }
  },

  updateInstance: async (id, payload) => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/einvites/cards/${id}/instance`,
        {
          method: "PUT",
          headers: getAuthHeaders(),
          body: JSON.stringify(payload),
        }
      );
      if (!response.ok) {
        let body;
        try {
          body = await response.json();
        } catch {
          body = await response.text();
        }
        throw new Error(
          typeof body === "string"
            ? body
            : body?.message || "Failed to update instance"
        );
      }
      return await response.json();
    } catch (error) {
      console.error("Error updating instance:", error);
      throw error;
    }
  },

  getAllEinvites: async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/einvites/cards`);
      if (!response.ok) throw new Error("Failed to fetch e-invites");
      const result = await response.json();
      if (result.success && result.data) {
        return result.data;
      }
      return result;
    } catch (error) {
      console.error("Error fetching e-invites:", error);
      throw error;
    }
  },

  // Get e-invites by category
  getEinvitesByCategory: async (category) => {
    try {
      const allCards = await einviteApi.getAllEinvites();
      const categoryMap = {
        "Wedding E-Invitations": "wedding_einvite",
        "Video Invitations": "video_invite",
        "Save The Date": "save_the_date",
      };
      const mappedCategory = categoryMap[category] || category;
      return allCards.filter((card) => card.cardType === mappedCategory);
    } catch (error) {
      console.error("Error fetching e-invites by category:", error);
      throw error;
    }
  },

  getEinviteById: async (id) => {
    try {
      const response = await fetch(`${API_BASE_URL}/einvites/cards/${id}`);
      if (!response.ok) throw new Error("Failed to fetch e-invite");
      return await response.json();
    } catch (error) {
      console.error("Error fetching e-invite:", error);
      throw error;
    }
  },

  createEinvite: async (einviteData) => {
    try {
      const response = await fetch(`${API_BASE_URL}/einvites/cards`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(einviteData),
      });
      if (!response.ok) throw new Error("Failed to create e-invite");
      return await response.json();
    } catch (error) {
      console.error("Error creating e-invite:", error);
      throw error;
    }
  },

  updateEinvite: async (id, einviteData) => {
    try {
      const response = await fetch(`${API_BASE_URL}/einvites/cards/${id}`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(einviteData),
      });
      if (!response.ok) {
        let errorBody;
        try {
          errorBody = await response.json();
        } catch (_) {
          errorBody = await response.text();
        }
        console.error("Update einvite failed", {
          status: response.status,
          statusText: response.statusText,
          url: `${API_BASE_URL}/einvites/cards/${id}`,
          requestBody: einviteData,
          responseBody: errorBody,
        });
        throw new Error(
          typeof errorBody === "string"
            ? errorBody
            : errorBody?.message || "Failed to update e-invite"
        );
      }
      return await response.json();
    } catch (error) {
      console.error("Error updating e-invite:", error);
      throw error;
    }
  },

  deleteEinvite: async (id) => {
    try {
      const response = await fetch(`${API_BASE_URL}/einvites/${id}`, {
        method: "DELETE",
      });
      if (!response.ok) throw new Error("Failed to delete e-invite");
      return await response.json();
    } catch (error) {
      console.error("Error deleting e-invite:", error);
      throw error;
    }
  },

  getUserEinvites: async (userId) => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/einvites/${userId}/einvites`
      );
      if (!response.ok) throw new Error("Failed to fetch user e-invites");
      return await response.json();
    } catch (error) {
      console.error("Error fetching user e-invites:", error);
      throw error;
    }
  },

  searchEinvites: async (query) => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/einvites/search?q=${encodeURIComponent(query)}`
      );
      if (!response.ok) throw new Error("Failed to search e-invites");
      return await response.json();
    } catch (error) {
      console.error("Error searching e-invites:", error);
      throw error;
    }
  },

  getCategories: async () => {
    try {
      // Since the categories endpoint doesn't exist, return default categories
      return [
        { value: "Wedding E-Invitations", label: "Wedding Cards" },
        { value: "Video Invitations", label: "Video Cards" },
        { value: "Save The Date", label: "Save The Date" },
      ];
    } catch (error) {
      console.error("Error fetching categories:", error);
      // Return default categories even if there's an error
      return [
        { value: "Wedding E-Invitations", label: "Wedding Cards" },
        { value: "Video Invitations", label: "Video Cards" },
        { value: "Save The Date", label: "Save The Date" },
      ];
    }
  },

  getEinvitesByTemplateStatus: async (isTemplate) => {
    try {
      const allCards = await einviteApi.getAllEinvites();
      return allCards.filter((card) => card.isTemplate === isTemplate);
    } catch (error) {
      console.error("Error fetching e-invites by template status:", error);
      throw error;
    }
  },

  getEinvitesByCategoryAndTemplate: async (category, isTemplate) => {
    try {
      const categoryCards = await einviteApi.getEinvitesByCategory(category);
      return categoryCards.filter((card) => card.isTemplate === isTemplate);
    } catch (error) {
      console.error(
        "Error fetching e-invites by category and template status:",
        error
      );
      throw error;
    }
  },

  // Get e-invites by cardType (wedding_einvite, video, save_the_date)
  getEinvitesByCardType: async (cardType) => {
    try {
      const response = await fetch(`${API_BASE_URL}/einvites/cards`);
      if (!response.ok) throw new Error("Failed to fetch e-invites");
      const result = await response.json();

      let allCards = [];
      if (result.success && result.data) {
        allCards = result.data;
      } else {
        allCards = result;
      }

      // Filter by cardType and only return templates
      return allCards.filter(
        (card) => card.cardType === cardType && card.isTemplate === true
      );
    } catch (error) {
      console.error("Error fetching e-invites by cardType:", error);
      throw error;
    }
  },

  // Get public e-invite instance for viewing (no auth required)
  getPublicEinviteInstance: async (id) => {
    try {
      // Try fetching as instance first
      let response = await fetch(
        `${API_BASE_URL}/einvites/cards/instances/${id}`
      );

      if (!response.ok) {
        response = await fetch(`${API_BASE_URL}/einvites/cards/${id}`);
      }

      if (!response.ok) {
        const errorText = await response.text();
        console.error("API Error:", {
          status: response.status,
          statusText: response.statusText,
          url: response.url,
          body: errorText,
        });
        throw new Error(
          `Failed to fetch e-invite: ${response.status} ${response.statusText}`
        );
      }

      const result = await response.json();
      return result;
    } catch (error) {
      console.error("Error fetching public e-invite instance:", error);
      throw error;
    }
  },
};
