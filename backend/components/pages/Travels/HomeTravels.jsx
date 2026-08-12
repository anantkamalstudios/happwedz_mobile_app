import React, { useState } from "react";

const HeroSearchSection = () => {
  const [searchInput, setSearchInput] = useState("");

  const handleSearch = (e) => {
    e.preventDefault();
    console.log("Search for:", searchInput);
  };

  return (
    <section
      className="d-flex align-items-center justify-content-center position-relative"
      style={{
        height: "100vh",
        backgroundImage:
          "url('https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&h=1080&fit=crop')",
        backgroundSize: "cover",
        backgroundPosition: "center",
      }}
    >
      {/* Overlay */}
      <div
        className="position-absolute top-0 start-0 w-100 h-100"
        style={{
          background:
            "linear-gradient(180deg, rgba(0,0,0,.3), rgba(0,0,0,.15), rgba(0,0,0,.25))",
        }}
      ></div>

      {/* Content */}
      <div className="container position-relative text-center text-white">
        <h1 className="fw-bold mb-4 display-4">Discover & book things to do</h1>

        <form
          onSubmit={handleSearch}
          className="mx-auto"
          style={{ maxWidth: "600px" }}
        >
          <div className="d-flex align-items-center bg-white rounded-pill p-2">
            <input
              type="text"
              className="form-control border-0 shadow-none rounded-pill"
              placeholder="india"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
            />

            <button
              type="submit"
              className="btn btn-primary rounded-pill fw-bold px-4 py-2 shadow-none ms-2"
            >
              Search
            </button>
          </div>
        </form>
      </div>
    </section>
  );
};

export default HeroSearchSection;
