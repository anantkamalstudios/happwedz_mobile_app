import React, { useState } from "react";
import RealWeddings from "../layouts/realWedding/RealWeddings";
import RealWeddingDetails from "../layouts/realWedding/RealWeddingDetails";

const RealWedding = () => {
  const [currentView, setCurrentView] = useState("list");
  const [selectedPost, setSelectedPost] = useState(null);

  const handlePostClick = (post) => {
    setSelectedPost(post);
    setCurrentView("detail");
  };

  const handleBackClick = () => {
    setCurrentView("list");
    setSelectedPost(null);
  };

  return (
    <div>
      {currentView === "list" ? (
        <RealWeddings onPostClick={handlePostClick} />
      ) : (
        <RealWeddingDetails post={selectedPost} onBackClick={handleBackClick} />
      )}
    </div>
  );
};

export default RealWedding;
