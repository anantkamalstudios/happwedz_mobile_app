import { Loader2, Plane, MapPin } from "lucide-react";

export default function SearchButton({ loading, onClick, type = "flight" }) {
  const isHotel = type === "hotel";

  return (
    <button
      className={`explore-btn ${loading ? "loading" : ""}`}
      onClick={onClick}
      disabled={loading}
    >
      {loading ? (
        <span className="explore-btn-content">
          <Loader2 size={18} className="spin" />
          {isHotel ? "Searching hotels..." : "Searching flights..."}
        </span>
      ) : (
        <span className="explore-btn-content">
          {isHotel ? <MapPin size={18} /> : <Plane size={18} />}
          {isHotel ? "Search hotels" : "Search flights"}
        </span>
      )}
    </button>
  );
}
