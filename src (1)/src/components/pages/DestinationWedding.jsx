import { useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import DestinationHero from "./DestinationHero";
import ImageCarousel from "./ImageCarousel";
import DestinationWeddingLocation from "./DestinationWeddingLocation";
import DestinationWeddingRealStories from "./DestinationWeddingRealStories";
import DestinationWeddingPlanningIdeas from "./DestinationWeddingPlanningIdeas";

const DestinationWedding = () => {
  const [currentIndex, setCurrentIndex] = useState(0);

  const images = [
    {
      url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop",
      alt: "Mountain landscape",
    },
    {
      url: "https://images.unsplash.com/photo-1511884642898-4c92249e20b6?w=800&h=600&fit=crop",
      alt: "Ocean waves",
    },
    {
      url: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=600&fit=crop",
      alt: "Forest path",
    },
  ];

  const goToPrevious = () => {
    setCurrentIndex((prevIndex) =>
      prevIndex === 0 ? images.length - 1 : prevIndex - 1
    );
  };

  const goToNext = () => {
    setCurrentIndex((prevIndex) =>
      prevIndex === images.length - 1 ? 0 : prevIndex + 1
    );
  };

  return (
    <div>
      <DestinationHero />
      <section>
        <div className="container">
          <ImageCarousel />
        </div>
      </section>

      <section>
        <DestinationWeddingLocation />
      </section>
      <section>
        <DestinationWeddingPlanningIdeas />
        <DestinationWeddingRealStories />
      </section>
    </div>
  );
};

export default DestinationWedding;
