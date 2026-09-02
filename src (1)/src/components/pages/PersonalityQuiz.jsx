import React, { useState, useEffect } from "react";
import axios from "../../services/api/axiosInstance";
import styles from "./AIFeatures.module.css";
import { FaHeart, FaSpinner, FaCheckCircle, FaMapMarkerAlt, FaStar, FaRupeeSign } from "react-icons/fa";

const QUESTIONS = [
    {
        id: 1,
        question: "Wedding Scale",
        option1: "Intimate (30–60 guests)",
        option2: "Grand (200+ guests)"
    },
    {
        id: 2,
        question: "Formality",
        option1: "Casual/barefoot",
        option2: "Black tie"
    },
    {
        id: 3,
        question: "Emotion",
        option1: "Romantic & heartfelt",
        option2: "Fun & wild"
    },
    {
        id: 4,
        question: "Culture",
        option1: "Full traditional rituals",
        option2: "Modern selective"
    },
    {
        id: 5,
        question: "Pace",
        option1: "Relaxed & flowing",
        option2: "Perfectly choreographed"
    },
    {
        id: 6,
        question: "Focus",
        option1: "Ceremony is main event",
        option2: "Reception is main event"
    },
    {
        id: 7,
        question: "Vibe",
        option1: "Timeless & classic",
        option2: "Unique & unexpected"
    }
];

const PersonalityQuiz = () => {
    const [partner1Answers, setPartner1Answers] = useState(Array(7).fill(null));
    const [partner2Answers, setPartner2Answers] = useState(Array(7).fill(null));
    const [result, setResult] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [venues, setVenues] = useState([]);
    const [venuesLoading, setVenuesLoading] = useState(false);

    const handleAnswer = (partner, questionIdx, value) => {
        if (partner === 1) {
            const newAnswers = [...partner1Answers];
            newAnswers[questionIdx] = value;
            setPartner1Answers(newAnswers);
        } else {
            const newAnswers = [...partner2Answers];
            newAnswers[questionIdx] = value;
            setPartner2Answers(newAnswers);
        }
    };

    const fetchRecommendedVenues = async (profileData) => {
        setVenuesLoading(true);
        try {
            // Query for royal wedding venues from the database
            const response = await axios.post("/ai/chat", {
                message: "Show me royal wedding venues",
                conversationHistory: []
            });

            if (response.data && response.data.vendors) {
                // Filter for venues with royal style
                const royalVenues = response.data.vendors.filter(vendor => 
                    vendor.category && vendor.category.toLowerCase().includes('venue')
                );
                setVenues(royalVenues.slice(0, 4)); // Show top 4 royal venues
            }
        } catch (err) {
            console.error("Failed to fetch venues:", err);
            // Fallback: try direct venue endpoint if available
            try {
                const fallbackResponse = await axios.get("/sub-Venues");
                if (fallbackResponse.data) {
                    // Filter for royal venues from direct API
                    const allVenues = Array.isArray(fallbackResponse.data) ? fallbackResponse.data : fallbackResponse.data.venues || [];
                    const royalVenues = allVenues
                        .filter(venue => 
                            venue.tags && venue.tags.some(tag => 
                                tag.toLowerCase().includes('royal') || 
                                tag.toLowerCase().includes('palace') ||
                                tag.toLowerCase().includes('heritage')
                            )
                        )
                        .slice(0, 4)
                        .map(venue => ({
                            name: venue.name || venue.venue_name,
                            location: venue.location?.city || venue.city || 'Location not specified',
                            rating: venue.rating || '4.5',
                            price_range: venue.starting_price ? `₹${venue.starting_price.toLocaleString('en-IN')}+` : 'Contact for pricing',
                            category: 'venue',
                            id: venue.id
                        }));
                    setVenues(royalVenues);
                }
            } catch (fallbackErr) {
                console.error("Fallback venue fetch failed:", fallbackErr);
            }
        } finally {
            setVenuesLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        setLoading(true);

        try {
            const response = await axios.post("/ai/personality-quiz", {
                partner1Answers,
                partner2Answers
            });

            setResult(response.data);
            
            // Save to localStorage for context injection
            localStorage.setItem('wedding_personality_profile', JSON.stringify(response.data));

            // Fetch recommended venues based on the profile
            await fetchRecommendedVenues(response.data);
            
        } catch (err) {
            console.error("Personality Quiz error:", err);
            setError("Couldn't process that — try again");
        } finally {
            setLoading(false);
        }
    };

    const allAnswered = partner1Answers.every(a => a !== null) && partner2Answers.every(a => a !== null);

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <FaHeart className={styles.headerIcon} />
                <h1>Let's AI Decide Your Vibe</h1>
                <p>Discover your unique wedding style and get personalized venue recommendations</p>
            </div>

            <form onSubmit={handleSubmit} className={styles.form}>
                {QUESTIONS.map((q, idx) => (
                    <div key={q.id} className={styles.questionBlock}>
                        <h3>Q{q.id}: {q.question}</h3>
                        
                        <div className={styles.partnerAnswers}>
                            <div className={styles.partnerColumn}>
                                <h4>Partner 1</h4>
                                <label className={`${styles.optionLabel} ${partner1Answers[idx] === 0 ? styles.selected : ''}`}>
                                    <input
                                        type="radio"
                                        name={`p1_q${q.id}`}
                                        checked={partner1Answers[idx] === 0}
                                        onChange={() => handleAnswer(1, idx, 0)}
                                    />
                                    {q.option1}
                                </label>
                                <label className={`${styles.optionLabel} ${partner1Answers[idx] === 1 ? styles.selected : ''}`}>
                                    <input
                                        type="radio"
                                        name={`p1_q${q.id}`}
                                        checked={partner1Answers[idx] === 1}
                                        onChange={() => handleAnswer(1, idx, 1)}
                                    />
                                    {q.option2}
                                </label>
                            </div>

                            <div className={styles.partnerColumn}>
                                <h4>Partner 2</h4>
                                <label className={`${styles.optionLabel} ${partner2Answers[idx] === 0 ? styles.selected : ''}`}>
                                    <input
                                        type="radio"
                                        name={`p2_q${q.id}`}
                                        checked={partner2Answers[idx] === 0}
                                        onChange={() => handleAnswer(2, idx, 0)}
                                    />
                                    {q.option1}
                                </label>
                                <label className={`${styles.optionLabel} ${partner2Answers[idx] === 1 ? styles.selected : ''}`}>
                                    <input
                                        type="radio"
                                        name={`p2_q${q.id}`}
                                        checked={partner2Answers[idx] === 1}
                                        onChange={() => handleAnswer(2, idx, 1)}
                                    />
                                    {q.option2}
                                </label>
                            </div>
                        </div>
                    </div>
                ))}

                <button type="submit" className={styles.submitBtn} disabled={!allAnswered || loading}>
                    {loading ? <><FaSpinner className={styles.spinner} /> Analyzing...</> : "Get Your Profile"}
                </button>

                {error && (
                    <div className={styles.error}>
                        {error}
                        <button onClick={() => setError(null)} className={styles.retryBtn}>Retry</button>
                    </div>
                )}
            </form>

            {result && (
                <div className={styles.results}>
                    <div className={styles.profileCard}>
                        <div className={styles.profileHeader}>
                            <FaCheckCircle className={styles.successIcon} />
                            <h2>🎉 {result.profile_name}</h2>
                        </div>
                        <p className={styles.profileDescription}>{result.description}</p>
                        
                        <div className={styles.traits}>
                            <h4>✨ Your Wedding Traits:</h4>
                            <div className={styles.traitsList}>
                                {result.traits && result.traits.map((trait, idx) => (
                                    <span key={idx} className={styles.traitBadge}>
                                        {trait}
                                    </span>
                                ))}
                            </div>
                        </div>

                        <div className={styles.styleDetails}>
                            <div className={styles.styleItem}>
                                <div className={styles.styleIcon}>🏛️</div>
                                <div>
                                    <strong>Perfect Venue Style:</strong>
                                    <p>{result.venue_style}</p>
                                </div>
                            </div>
                            <div className={styles.styleItem}>
                                <div className={styles.styleIcon}>🎨</div>
                                <div>
                                    <strong>Ideal Decor Style:</strong>
                                    <p>{result.decor_style}</p>
                                </div>
                            </div>
                        </div>

                        {result.mismatch_alert && (
                            <div className={styles.mismatchAlert}>
                                <strong>💡 Partnership Note:</strong> {result.mismatch_alert}
                            </div>
                        )}

                        <div className={styles.lensBox}>
                            <h4>🎯 Your AI Planning Assistant:</h4>
                            <p>{result.recommendations_lens}</p>
                            <small>✨ This profile will personalize all future AI recommendations just for you!</small>
                        </div>
                    </div>

                    {/* Venue Recommendations Section */}
                    <div className={styles.venueRecommendations}>
                        <div className={styles.venueHeader}>
                            <h3>👑 Royal Wedding Venues</h3>
                            <p>Discover majestic royal venues perfect for your dream wedding</p>
                        </div>

                        {venuesLoading ? (
                            <div className={styles.venueLoading}>
                                <FaSpinner className={styles.spinner} />
                                <p>Finding your perfect venues...</p>
                            </div>
                        ) : venues.length > 0 ? (
                            <div className={styles.venueGrid}>
                                {venues.map((venue, idx) => (
                                    <div key={idx} className={styles.venueCard}>
                                        <div className={styles.venueImagePlaceholder}>
                                            🏛️
                                        </div>
                                        <div className={styles.venueContent}>
                                            <h4>{venue.name}</h4>
                                            <div className={styles.venueLocation}>
                                                <FaMapMarkerAlt />
                                                <span>{venue.location}</span>
                                            </div>
                                            <div className={styles.venueRating}>
                                                <FaStar />
                                                <span>{venue.rating || 'N/A'}</span>
                                            </div>
                                            <div className={styles.venuePrice}>
                                                <FaRupeeSign />
                                                <span>{venue.price_range || 'Contact for pricing'}</span>
                                            </div>
                                            <div className={styles.venueMatch}>
                                                <span className={styles.matchBadge}>
                                                    👑 Royal Wedding Venue
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className={styles.noVenues}>
                                <p>🔍 No venues found matching your style. Try exploring our venue directory!</p>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

export default PersonalityQuiz;
