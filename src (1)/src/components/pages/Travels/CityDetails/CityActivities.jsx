import React, { useState } from "react";
import { useParams } from "react-router-dom";
import "./CityActivities.css";

const CityActivities = () => {
  const { cityName } = useParams();

  // Normalize city name for data lookup (lowercase)
  const cityKey = cityName?.toLowerCase();

  const gygAffiliateLinks = {
    rome: "https://www.getyourguide.com/rome-l33/?partner_id=235SCEF&utm_medium=online_publisher&cmp=rome",
    paris:
      "https://www.getyourguide.com/paris-l16/?partner_id=235SCEF&utm_medium=online_publisher",
    london:
      "https://www.getyourguide.com/london-l57/?partner_id=235SCEF&utm_medium=online_publisher",
    "new york city":
      "https://www.getyourguide.com/new-york-city-l59/?partner_id=235SCEF&utm_medium=online_publisher",
    dubai:
      "https://www.getyourguide.com/dubai-l173/?partner_id=235SCEF&utm_medium=online_publisher",
    barcelona:
      "https://www.getyourguide.com/barcelona-l45/?partner_id=235SCEF&utm_medium=online_publisher",
  };

  const viatorAffiliateLinks = {
    rome: "https://www.viator.com/Rome/d511-ttd?pid=P00234765&mcid=42383&medium=link",
    paris:
      "https://www.viator.com/Paris/d479-ttd?pid=P00234765&mcid=42383&medium=link",
    london:
      "https://www.viator.com/London/d737-ttd?pid=P00234765&mcid=42383&medium=link",
    "new york city":
      "https://www.viator.com/New-York-City/d687-ttd?pid=P00234765&mcid=42383&medium=link",
    dubai:
      "https://www.viator.com/Dubai/d828-ttd?pid=P00234765&mcid=42383&medium=link",
    barcelona:
      "https://www.viator.com/Barcelona/d562-ttd?pid=P00234765&mcid=42383&medium=link",
  };

  // Data for different cities
  const cityData = {
    rome: {
      title: "Rome, Italy",
      subtitle:
        "The Eternal City with top tours and activities from trusted partners",
      activities: [
        {
          id: 3,
          provider: "Viator",
          title: "Best Rome tours and excursions",
          description:
            "Book unique experiences, day trips, and guided tours. From food walking tours to ancient ruins.",
          link: viatorAffiliateLinks.rome,
          buttonText: "View on Viator",
          tag: "Great value",
          highlights: [
            {
              text: "Colosseum tickets and tours on Viator",
              link: "https://www.viator.com/Rome-attractions/Colosseum/d511-a701?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Trevi Fountain tours and experiences on Viator",
              link: "https://www.viator.com/Rome-attractions/Trevi-Fountain/d511-a717?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Pantheon tours and tickets on Viator",
              link: "https://www.viator.com/Rome-attractions/Pantheon/d511-a51?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Roman Forum tours and tickets on Viator",
              link: "https://www.viator.com/Rome-attractions/Roman-Forum/d511-a705?pid=P00234765&mcid=42383&medium=link",
            },
          ],
        },
        {
          id: 1,
          provider: "GetYourGuide",
          title: "Premium Rome tours and fast-track tickets",
          description:
            "Skip the line at the Colosseum, explore the Vatican Museums, and discover hidden gems with local guides.",
          link: "https://www.getyourguide.com/rome-l33/?partner_id=235SCEF&utm_medium=online_publisher&cmp=rome",
          buttonText: "View on GetYourGuide",
          tag: "Most popular",
          featured: true,
          highlights: [
            {
              text: "Colosseum skip-the-line tickets on GetYourGuide",
              link: "https://www.getyourguide.com/colosseum-l2619/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Vatican Museums & Sistine Chapel tickets on GetYourGuide",
              link: "https://www.getyourguide.com/vatican-museums-l2738/?partner_id=235SCEF&utm_medium=online_publisher",
            },
          ],
        },
        {
          id: 2,
          provider: "Tiqets",
          title: "All Rome attractions in one view",
          description:
            "Explore a curated list of the best things to do in Rome, from free walking tours to premium experiences.",
          link: "https://tiqets.tpk.lu/ohhcxDDy",
          buttonText: "View on Tiqets",
          tag: "Explore more",
          highlights: [
            {
              text: "Colosseum tickets and tours on Tiqets",
              link: "https://tiqets.tpk.lu/ohhcxDDy",
            },
            {
              text: "Vatican Museums tickets on Tiqets",
              link: "https://tiqets.tpk.lu/7SG695H5",
            },
            {
              text: "Borghese Gallery tickets on Tiqets",
              link: "https://tiqets.tpk.lu/89GVOgKp",
            },
          ],
        },
      ],
    },
    paris: {
      title: "Paris, France",
      subtitle: "Iconic landmarks and world-class museums in the City of Light",
      activities: [
        {
          id: 3,
          provider: "Viator",
          title: "Best Paris tours and excursions",
          description:
            "From river cruises to landmark tours, discover Paris with local guides.",
          link: viatorAffiliateLinks.paris,
          buttonText: "View on Viator",
          tag: "Great value",
          highlights: [
            {
              text: "Eiffel Tower tours and tickets on Viator",
              link: "https://www.viator.com/Paris-attractions/Eiffel-Tower/d479-a89?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Louvre Museum tours and tickets on Viator",
              link: "https://www.viator.com/Paris-attractions/Louvre-Museum/d479-a73?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Arc de Triomphe tours and tickets on Viator",
              link: "https://www.viator.com/Paris-attractions/Arc-de-Triomphe/d479-a573?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Notre Dame Cathedral tours and tickets on Viator",
              link: "https://www.viator.com/France-attractions/Notre-Dame-de-Lorette/d51-a18421?pid=P00234765&mcid=42383&medium=link",
            },
          ],
        },
        {
          id: 1,
          provider: "GetYourGuide",
          title: "Top Paris tickets and fast-track experiences",
          description:
            "Book tickets and tours for Paris icons like the Eiffel Tower, Louvre, and more.",
          link: gygAffiliateLinks.paris,
          buttonText: "View on GetYourGuide",
          tag: "Most popular",
          featured: true,
          highlights: [
            {
              text: "Eiffel Tower tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/eiffel-tower-l2600/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Louvre Museum tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/louvre-museum-l3224/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Arc de Triomphe experiences on GetYourGuide",
              link: "https://www.getyourguide.com/arc-de-triomphe-l3238/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Notre Dame Cathedral experiences on GetYourGuide",
              link: "https://www.getyourguide.com/notre-dame-cathedral-l3230/?partner_id=235SCEF&utm_medium=online_publisher",
            },
          ],
        },
        {
          id: 2,
          provider: "Tiqets",
          title: "All Paris attractions in one view",
          description:
            "Compare Paris attractions and experiences in one place with flexible options.",
          link: "https://tiqets.tpk.lu/9EvuMkFx",
          buttonText: "View on Tiqets",
          tag: "Explore more",
          highlights: [
            {
              text: "Seine River Cruises tickets on Tiqets",
              link: "https://tiqets.tpk.lu/9EvuMkFx",
            },
            {
              text: "Eiffel Tower tickets on Tiqets",
              link: "https://tiqets.tpk.lu/m66ezp5e",
            },
            {
              text: "Disneyland® Paris tickets on Tiqets",
              link: "https://tiqets.tpk.lu/386CoF1y",
            },
          ],
        },
      ],
    },
    london: {
      title: "London, United Kingdom",
      subtitle: "Historic landmarks and modern icons along the River Thames",
      activities: [
        {
          id: 3,
          provider: "Viator",
          title: "Best London tours and excursions",
          description:
            "See royal palaces, historic sites, and modern London with expert guides.",
          link: viatorAffiliateLinks.london,
          buttonText: "View on Viator",
          tag: "Great value",
          highlights: [
            {
              text: "Tower of London tickets and tours on Viator",
              link: "https://www.viator.com/London-attractions/Tower-of-London/d737-a93?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "British Museum tours and experiences on Viator",
              link: "https://www.viator.com/London-attractions/British-Museum/d737-a1388?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "London Eye tickets and experiences on Viator",
              link: "https://www.viator.com/London-attractions/London-Eye/d737-a1400?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Tower Bridge tours and experiences on Viator",
              link: "https://www.viator.com/London-attractions/Tower-Bridge/d737-a1379?pid=P00234765&mcid=42383&medium=link",
            },
          ],
        },
        {
          id: 1,
          provider: "GetYourGuide",
          title: "Top London tickets and fast-track experiences",
          description:
            "Book tickets and tours for London icons like the Tower of London, London Eye, and more.",
          link: gygAffiliateLinks.london,
          buttonText: "View on GetYourGuide",
          tag: "Most popular",
          featured: true,
          highlights: [
            {
              text: "Tower of London tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/tower-of-london-l2708/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "British Museum tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/british-museum-l3190/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "The London Eye tickets and experiences on GetYourGuide",
              link: "https://www.getyourguide.com/the-london-eye-l2711/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Tower Bridge experiences on GetYourGuide",
              link: "https://www.getyourguide.com/tower-bridge-l2713/?partner_id=235SCEF&utm_medium=online_publisher",
            },
          ],
        },
        {
          id: 2,
          provider: "Tiqets",
          title: "All London attractions in one view",
          description:
            "Compare London attractions and experiences in one place with flexible options.",
          link: "https://www.getyourguide.com/s/?q=London&customerSearch=1",
          buttonText: "Explore more",
          tag: "Explore more",
          highlights: [
            "Curated list of top London attractions",
            "Flexible durations and group sizes",
            "Instant online booking",
          ],
        },
      ],
    },

    "new york city": {
      title: "New York City, USA",
      subtitle:
        "The city that never sleeps, featuring iconic skylines and landmarks",
      activities: [
        {
          id: 3,
          provider: "Viator",
          title: "Best New York City tours and excursions",
          description:
            "Experience the Big Apple with top-rated tours, from Broadway to the Statue of Liberty.",
          link: viatorAffiliateLinks["new york city"],
          buttonText: "View on Viator",
          tag: "Great value",
          highlights: [
            {
              text: "Washington, D.C. day trips and tours on Viator",
              link: "https://www.viator.com/Washington-DC/d657-ttd?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Statue of Liberty tours and tickets on Viator",
              link: "https://www.viator.com/New-York-City-attractions/Statue-of-Liberty/d687-a16?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Brooklyn Bridge tours and experiences on Viator",
              link: "https://www.viator.com/New-York-City-attractions/Brooklyn-Bridge/d687-a1282?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Empire State Building tickets and tours on Viator",
              link: "https://www.viator.com/New-York-City-attractions/Empire-State-Building/d687-a19?pid=P00234765&mcid=42383&medium=link",
            },
          ],
        },
        {
          id: 1,
          provider: "GetYourGuide",
          title: "Top New York City tickets and fast-track experiences",
          description:
            "Book tickets and tours for NYC icons like the Empire State Building, Statue of Liberty, and more.",
          link: gygAffiliateLinks["new york city"],
          buttonText: "View on GetYourGuide",
          tag: "Most popular",
          featured: true,
          highlights: [
            {
              text: "Washington tours from New York on GetYourGuide",
              link: "https://www.getyourguide.com/washington-va-l209140/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Brooklyn tours and experiences on GetYourGuide",
              link: "https://www.getyourguide.com/brooklyn-l2034/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Empire State Building tickets on GetYourGuide",
              link: "https://www.getyourguide.com/empire-state-building-l2608/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Statue of Liberty tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/statue-of-liberty-l2612/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            "Free cancellation on many activities",
          ],
        },
        {
          id: 2,
          provider: "Tiqets",
          title: "All New York City attractions in one view",
          description:
            "Compare NYC attractions and experiences in one place with flexible options.",
          link: "https://www.getyourguide.com/s/?q=New%20York%20City&customerSearch=1",
          buttonText: "Explore more",
          tag: "Explore more",
          highlights: [
            "Curated list of top NYC attractions",
            "Flexible durations and group sizes",
            "Instant online booking",
          ],
        },
      ],
    },
    dubai: {
      title: "Dubai, UAE",
      subtitle:
        "The city of superlatives, from the world's tallest building to man-made islands",
      activities: [
        {
          id: 3,
          provider: "Viator",
          title: "Best Dubai tours and excursions",
          description:
            "Experience the desert, modern architecture, and luxury of Dubai with top-rated tours.",
          link: viatorAffiliateLinks.dubai,
          buttonText: "View on Viator",
          tag: "Great value",
          highlights: [
            {
              text: "Burj Khalifa tours and tickets on Viator",
              link: "https://www.viator.com/Dubai-attractions/Burj-Khalifa/d828-a1622?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Dubai Mall experiences and tickets on Viator",
              link: "https://www.viator.com/Dubai-attractions/Dubai-Mall/d828-a11308?pid=P00234765&mcid=42383&medium=link",
            },
          ],
        },
        {
          id: 1,
          provider: "GetYourGuide",
          title: "Top Dubai tickets and fast-track experiences",
          description:
            "Book tickets for Dubai icons like the Burj Khalifa, Dubai Mall, and more.",
          link: gygAffiliateLinks.dubai,
          buttonText: "View on GetYourGuide",
          tag: "Most popular",
          featured: true,
          highlights: [
            {
              text: "Burj Khalifa tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/burj-khalifa-l2703/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Dubai Mall tickets and experiences on GetYourGuide",
              link: "https://www.getyourguide.com/dubai-mall-l4308/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Dubai Fountain tickets and experiences on GetYourGuide",
              link: "https://www.getyourguide.com/dubai-fountain-l3305/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Dubai Frame tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/dubai-frame-l87469/?partner_id=235SCEF&utm_medium=online_publisher",
            },
          ],
        },
        {
          id: 2,
          provider: "Tiqets",
          title: "All Dubai attractions in one view",
          description:
            "Compare Dubai attractions and experiences in one place with flexible options.",
          link: "https://www.getyourguide.com/s/?q=Dubai&customerSearch=1",
          buttonText: "Explore more",
          tag: "Explore more",
          highlights: [
            "Curated list of top Dubai attractions",
            "Flexible durations and group sizes",
            "Instant online booking",
          ],
        },
      ],
    },
    barcelona: {
      title: "Barcelona, Spain",
      subtitle: "Modernist architecture, seaside views, and vibrant city life",
      activities: [
        {
          id: 3,
          provider: "Viator",
          title: "Best Barcelona tours and excursions",
          description:
            "Discover Gaudí’s masterpieces, historic neighborhoods, and Mediterranean views with expert guides.",
          link: viatorAffiliateLinks.barcelona,
          buttonText: "View on Viator",
          tag: "Great value",
          highlights: [
            {
              text: "Park Güell tours and tickets on Viator",
              link: "https://www.viator.com/Barcelona-attractions/Park-Guell/d562-a831?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "Casa Batlló tours and tickets on Viator",
              link: "https://www.viator.com/Barcelona-attractions/Casa-Batllo/d562-a9858?pid=P00234765&mcid=42383&medium=link",
            },
            {
              text: "La Pedrera (Casa Milà) tours and tickets on Viator",
              link: "https://www.viator.com/Barcelona-attractions/La-Pedrera-Casa-Mila/d562-a833?pid=P00234765&mcid=42383&medium=link",
            },
          ],
        },
        {
          id: 1,
          provider: "GetYourGuide",
          title: "Top Barcelona tickets and fast-track experiences",
          description:
            "Book tickets and tours for Barcelona icons like Park Güell and Casa Batlló.",
          link: gygAffiliateLinks.barcelona,
          buttonText: "View on GetYourGuide",
          tag: "Most popular",
          featured: true,
          highlights: [
            {
              text: "Park Güell tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/park-guell-l3032/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "Casa Batlló tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/casa-batllo-l3027/?partner_id=235SCEF&utm_medium=online_publisher",
            },
            {
              text: "La Pedrera tickets and tours on GetYourGuide",
              link: "https://www.getyourguide.com/las-palmas-l423/?partner_id=235SCEF&utm_medium=online_publisher",
            },
          ],
        },
        {
          id: 2,
          provider: "Tiqets",
          title: "All Barcelona attractions in one view",
          description:
            "Compare Barcelona attractions and experiences in one place with flexible options.",
          link: "https://www.getyourguide.com/s/?q=Barcelona&customerSearch=1",
          buttonText: "Explore more",
          tag: "Explore more",
          highlights: [
            "Curated list of top Barcelona attractions",
            "Flexible durations and group sizes",
            "Instant online booking",
          ],
        },
      ],
    },
    // Fallback data for other cities
    default: {
      title: cityName || "Discover City",
      subtitle: `Explore the best activities and tours in ${cityName}`,
      activities: [
        {
          id: 3,
          provider: "Viator",
          title: `${cityName} Tours & Excursions`,
          description:
            "Discover local culture, food, and landmarks with expert guides.",
          link:
            viatorAffiliateLinks[cityKey] ||
            `https://www.viator.com/searchResults/all?text=${cityName}&pid=P00234765&mcid=42383`,
          buttonText: "View on Viator",
          tag: "Great value",
          highlights: [
            "Handpicked tours with flexible scheduling",
            "Secure payments and support",
            "From day trips to short activities",
          ],
        },
        {
          id: 1,
          provider: "GetYourGuide",
          title: `Top Things to Do in ${cityName}`,
          description:
            "Find the best rated tours and activities with free cancellation.",
          link:
            gygAffiliateLinks[cityKey] ||
            `https://www.getyourguide.com/s/?q=${cityName}&partner_id=235SCEF`,
          buttonText: "View on GetYourGuide",
          tag: "Most popular",
          featured: true,
          highlights: [
            "Wide range of tours and tickets",
            "Verified reviews from real travelers",
            "Free cancellation on many options",
          ],
        },
        {
          id: 2,
          provider: "Tiqets",
          title: "All Rome attractions in one view",
          description:
            "Explore a curated list of the best things to do in Rome, from free walking tours to premium experiences.",
          link: "https://www.getyourguide.com/s/?q=Rome&customerSearch=1", // Fallback generic search
          buttonText: "View on Tiqets",
          tag: "Explore more",
          // discount: "Top picks",
          highlights: [
            "Compare activities across categories",
            "Flexible durations and group sizes",
            "Instant online booking",
          ],
        },
      ],
    },
  };

  const currentCity = cityData[cityKey] || cityData.default;
  const heroCategories = [
    "Top attractions",
    "Day trips",
    "Museums",
    "Food & wine",
    "Guided tours",
  ];
  const [filters, setFilters] = useState({
    country: "Italy",
    city: cityName || "Rome",
    attractionType: "Top attractions",
  });
  const [activeCategory, setActiveCategory] = useState(heroCategories[0]);

  const handleFilterChange = (field, value) => {
    setFilters((prev) => ({ ...prev, [field]: value }));
  };

  return (
    <div className="city-activities-container">
      <div className="container">
        <div className="city-hero-section">
          <h2 className="hero-title">
            Choose an experience and explore {currentCity.title}
          </h2>
          <p className="hero-subtitle">
            Pick a category to see the best options from our partners.
          </p>
          <div className="hero-chips">
            {heroCategories.map((category) => (
              <button
                key={category}
                type="button"
                className={
                  category === activeCategory
                    ? "hero-chip hero-chip-active"
                    : "hero-chip"
                }
                onClick={() => setActiveCategory(category)}
              >
                {category}
              </button>
            ))}
          </div>
        </div>

        <div className="city-filter-bar">
          <div className="filter-group">
            <span className="filter-label">Country</span>
            <div className="filter-select">
              <select
                value={filters.country}
                onChange={(e) => handleFilterChange("country", e.target.value)}
              >
                <option value="Italy">Italy</option>
                <option value="France">France</option>
                <option value="Netherlands">Netherlands</option>
                <option value="USA">USA</option>
              </select>
            </div>
          </div>

          <div className="filter-group">
            <span className="filter-label">City</span>
            <div className="filter-select">
              <select
                value={filters.city}
                onChange={(e) => handleFilterChange("city", e.target.value)}
              >
                <option value={cityName || "Rome"}>{cityName || "Rome"}</option>
                <option value="Paris">Paris</option>
                <option value="Amsterdam">Amsterdam</option>
                <option value="New York">New York</option>
              </select>
            </div>
          </div>

          <div className="filter-group">
            <span className="filter-label">Top attraction</span>
            <div className="filter-select">
              <select
                value={filters.attractionType}
                onChange={(e) =>
                  handleFilterChange("attractionType", e.target.value)
                }
              >
                <option value="Top attractions">Top attractions</option>
                <option value="Day trips">Day trips</option>
                <option value="Museums">Museums</option>
                <option value="Food & wine">Food & wine</option>
                <option value="Guided tours">Guided tours</option>
              </select>
            </div>
          </div>
        </div>

        <div className="activities-grid">
          {currentCity.activities.map((activity) => (
            <a
              key={activity.id}
              href={activity.link}
              target="_blank"
              rel="noopener noreferrer"
              className={`activity-card ${activity.featured ? "featured" : ""}`}
            >
              <div className="activity-card-header">
                <div className="activity-tag">{activity.tag}</div>
                {activity.discount && (
                  <div className="activity-discount">{activity.discount}</div>
                )}
              </div>

              <div className="activity-body">
                <div className="activity-provider">{activity.provider}</div>
                <h3 className="activity-title">{activity.title}</h3>
                <p className="activity-description">{activity.description}</p>

                {activity.highlights && (
                  <ul className="activity-features">
                    {activity.highlights.map((item, index) => {
                      const isObject =
                        typeof item === "object" && item !== null;
                      const text = isObject ? item.text : item;
                      const link = isObject ? item.link : undefined;

                      return (
                        <li key={index}>
                          <span className="feature-bullet" />
                          {link ? (
                            <a
                              href={link}
                              target="_blank"
                              rel="noopener noreferrer"
                            >
                              {text}
                            </a>
                          ) : (
                            <span>{text}</span>
                          )}
                        </li>
                      );
                    })}
                  </ul>
                )}

                <div className="activity-footer">
                  <span className="activity-action">
                    {activity.buttonText}
                    <span>→</span>
                  </span>
                </div>
              </div>
            </a>
          ))}
        </div>
      </div>
    </div>
  );
};

export default CityActivities;
