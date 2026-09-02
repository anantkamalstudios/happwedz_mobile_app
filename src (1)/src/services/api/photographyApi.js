// Photography API service
import axios from "axios";

const getBaseUrl = () => {
  const envUrl = import.meta.env.VITE_API_URL || "https://happywedz.com/api";
  if (envUrl.includes("localhost")) {
    return envUrl.replace(/\/api$/, "");
  }
  return envUrl;
};
const BASE_URL = getBaseUrl();

// Get main photography types
export const getPhotographyTypes = async () => {
  const response = await axios.get(`${BASE_URL}/photography-types`);
  return response.data;
};

// Get sub photography categories
export const getPhotographyCategories = async () => {
  const response = await axios.get(`${BASE_URL}/photography-categories`);
  return response.data;
};

// Get main+sub photography types with categories
export const getPhotographyTypesWithCategories = async () => {
  const response = await axios.get(
    `${BASE_URL}/photography-types/with-categories`
  );
  return response.data;
};

// Get photos by ID
export const getPhotographyById = async (id) => {
  const response = await axios.get(`${BASE_URL}/photography/photography/${id}`);
  return response.data;
};

// Get all photos
export const getAllPhotography = async () => {
  const response = await axios.get(`${BASE_URL}/photography/photography`);
  return response.data;
};

// Get photos by type
export const getPhotographyByType = async (id) => {
  const response = await axios.get(`${BASE_URL}/photography/filter?type=${id}`);
  return response.data;
};

// Get photos by subcategory
export const getPhotographyByCategory = async (id, city) => {
  const url = city 
    ? `${BASE_URL}/photography/filter?category=${id}&city=${city}`
    : `${BASE_URL}/photography/filter?category=${id}`;
  const response = await axios.get(url);
  return response.data;
};
