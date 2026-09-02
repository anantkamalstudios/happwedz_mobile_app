/**
 * Utility function to parse JSON responses from Llama 70B
 * Handles markdown code fences that sometimes wrap the JSON
 */
export function parseLlamaJSON(raw) {
    try {
        const cleaned = raw.replace(/```json/g, '').replace(/```/g, '').trim();
        return JSON.parse(cleaned);
    } catch (error) {
        console.error("Failed to parse Llama JSON:", error);
        throw new Error("Couldn't process that — try again");
    }
}
