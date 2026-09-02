import React, { useState } from "react";
import axios from "../../services/api/axiosInstance";
import styles from "./AIFeatures.module.css";
import { FaMagic, FaSpinner } from "react-icons/fa";

const CULTURES = [
    "Indian (Hindu)", "Indian (Muslim)", "Indian (Sikh)", "Indian (Christian)",
    "Chinese", "Japanese", "Korean", "Thai", "Vietnamese",
    "Mexican", "Brazilian", "Colombian", "Argentinian",
    "Italian", "French", "Spanish", "Greek", "Portuguese",
    "British", "Irish", "Scottish", "German", "Dutch",
    "Nigerian", "Ghanaian", "Ethiopian", "Moroccan",
    "Lebanese", "Turkish", "Persian", "Egyptian"
];

const CEREMONY_TYPES = ["Religious", "Civil", "Symbolic"];

const CultureBlender = () => {
    const [culture1, setCulture1] = useState("");
    const [culture2, setCulture2] = useState("");
    const [ceremonyType, setCeremonyType] = useState("");
    
    // Simplified state structure
    const [partner1Rituals, setPartner1Rituals] = useState(2);
    const [partner1Attire, setPartner1Attire] = useState(2);
    const [partner1Food, setPartner1Food] = useState(2);
    const [partner1Music, setPartner1Music] = useState(2);
    const [partner1VenueStyle, setPartner1VenueStyle] = useState(2);
    
    const [partner2Rituals, setPartner2Rituals] = useState(2);
    const [partner2Attire, setPartner2Attire] = useState(2);
    const [partner2Food, setPartner2Food] = useState(2);
    const [partner2Music, setPartner2Music] = useState(2);
    const [partner2VenueStyle, setPartner2VenueStyle] = useState(2);
    
    const [result, setResult] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        setLoading(true);

        try {
            // Get recommendations_lens from localStorage if available
            const savedProfile = localStorage.getItem('wedding_personality_profile');
            const recommendationsLens = savedProfile ? JSON.parse(savedProfile).recommendations_lens : null;

            const partner1Priorities = {
                rituals: partner1Rituals,
                attire: partner1Attire,
                food: partner1Food,
                music: partner1Music,
                venueStyle: partner1VenueStyle
            };

            const partner2Priorities = {
                rituals: partner2Rituals,
                attire: partner2Attire,
                food: partner2Food,
                music: partner2Music,
                venueStyle: partner2VenueStyle
            };

            const response = await axios.post("/ai/culture-blender", {
                culture1,
                culture2,
                ceremonyType,
                partner1Priorities,
                partner2Priorities,
                recommendationsLens
            });

            setResult(response.data);
        } catch (err) {
            console.error("Culture Blender error:", err);
            setError("Couldn't process that — try again");
        } finally {
            setLoading(false);
        }
    };

    const canSubmit = culture1 && culture2 && ceremonyType;

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <FaMagic className={styles.headerIcon} />
                <h1>Multi-Culture Blender</h1>
                <p>Blend two cultures into a beautiful ceremony</p>
            </div>

            <form onSubmit={handleSubmit} className={styles.form}>
                <div className={styles.row}>
                    <div className={styles.field}>
                        <label>Partner 1 Culture</label>
                        <select value={culture1} onChange={(e) => setCulture1(e.target.value)} required>
                            <option value="">Select culture</option>
                            {CULTURES.map(c => <option key={c} value={c}>{c}</option>)}
                        </select>
                    </div>

                    <div className={styles.field}>
                        <label>Partner 2 Culture</label>
                        <select value={culture2} onChange={(e) => setCulture2(e.target.value)} required>
                            <option value="">Select culture</option>
                            {CULTURES.map(c => <option key={c} value={c}>{c}</option>)}
                        </select>
                    </div>
                </div>

                <div className={styles.field}>
                    <label>Ceremony Type</label>
                    <div className={styles.radioGroup}>
                        {CEREMONY_TYPES.map(type => (
                            <label key={type} className={styles.radioLabel}>
                                <input
                                    type="radio"
                                    name="ceremonyType"
                                    value={type}
                                    checked={ceremonyType === type}
                                    onChange={(e) => setCeremonyType(e.target.value)}
                                    required
                                />
                                {type}
                            </label>
                        ))}
                    </div>
                </div>

                <div className={styles.prioritiesSection}>
                    <h3>Partner 1 Priorities</h3>
                    
                    <div className={styles.sliderField}>
                        <label>Rituals</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner1Rituals}
                                onChange={(e) => {
                                    console.log('Rituals changed to:', e.target.value);
                                    setPartner1Rituals(parseInt(e.target.value));
                                }}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner1Rituals}</span>
                        </div>
                    </div>

                    <div className={styles.sliderField}>
                        <label>Attire</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner1Attire}
                                onChange={(e) => setPartner1Attire(parseInt(e.target.value))}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner1Attire}</span>
                        </div>
                    </div>

                    <div className={styles.sliderField}>
                        <label>Food</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner1Food}
                                onChange={(e) => setPartner1Food(parseInt(e.target.value))}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner1Food}</span>
                        </div>
                    </div>

                    <div className={styles.sliderField}>
                        <label>Music</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner1Music}
                                onChange={(e) => setPartner1Music(parseInt(e.target.value))}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner1Music}</span>
                        </div>
                    </div>

                    <div className={styles.sliderField}>
                        <label>Venue Style</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner1VenueStyle}
                                onChange={(e) => setPartner1VenueStyle(parseInt(e.target.value))}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner1VenueStyle}</span>
                        </div>
                    </div>
                </div>

                <div className={styles.prioritiesSection}>
                    <h3>Partner 2 Priorities</h3>
                    
                    <div className={styles.sliderField}>
                        <label>Rituals</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner2Rituals}
                                onChange={(e) => setPartner2Rituals(parseInt(e.target.value))}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner2Rituals}</span>
                        </div>
                    </div>

                    <div className={styles.sliderField}>
                        <label>Attire</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner2Attire}
                                onChange={(e) => setPartner2Attire(parseInt(e.target.value))}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner2Attire}</span>
                        </div>
                    </div>

                    <div className={styles.sliderField}>
                        <label>Food</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner2Food}
                                onChange={(e) => setPartner2Food(parseInt(e.target.value))}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner2Food}</span>
                        </div>
                    </div>

                    <div className={styles.sliderField}>
                        <label>Music</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner2Music}
                                onChange={(e) => setPartner2Music(parseInt(e.target.value))}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner2Music}</span>
                        </div>
                    </div>

                    <div className={styles.sliderField}>
                        <label>Venue Style</label>
                        <div className={styles.sliderContainer}>
                            <span>Skip</span>
                            <input
                                type="range"
                                min="1"
                                max="4"
                                step="1"
                                value={partner2VenueStyle}
                                onChange={(e) => setPartner2VenueStyle(parseInt(e.target.value))}
                                style={{ cursor: 'pointer' }}
                            />
                            <span>Must Have</span>
                            <span className={styles.sliderValue}>{partner2VenueStyle}</span>
                        </div>
                    </div>
                </div>

                <button type="submit" className={styles.submitBtn} disabled={!canSubmit || loading}>
                    {loading ? <><FaSpinner className={styles.spinner} /> Generating...</> : "Blend Cultures"}
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
                    {result.conflict_alerts && result.conflict_alerts.length > 0 && (
                        <div className={styles.conflictPanel}>
                            <h3>⚠️ Potential Conflicts</h3>
                            {result.conflict_alerts.map((alert, idx) => (
                                <div key={idx} className={styles.conflictCard}>
                                    <h4>{alert.topic}</h4>
                                    <p>{alert.description}</p>
                                    <div className={styles.resolutions}>
                                        <strong>Resolutions:</strong>
                                        <ul>
                                            {alert.resolutions.map((res, i) => <li key={i}>{res}</li>)}
                                        </ul>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}

                    <div className={styles.ceremonyFlow}>
                        <h3>Ceremony Flow</h3>
                        {result.ceremony_sections && result.ceremony_sections.map((section, idx) => (
                            <div key={idx} className={styles.ceremonyCard}>
                                <div className={styles.ceremonyHeader}>
                                    <h4>{section.name}</h4>
                                    <span className={styles.originBadge}>{section.origin}</span>
                                </div>
                                <p className={styles.description}>{section.description}</p>
                                <div className={styles.ceremonyMeta}>
                                    <span>⏱️ {section.duration_mins} mins</span>
                                </div>
                                {section.guest_explanation && (
                                    <div className={styles.guestNote}>
                                        <strong>For guests:</strong> {section.guest_explanation}
                                    </div>
                                )}
                                {section.officiant_note && (
                                    <div className={styles.officiantNote}>
                                        <strong>Officiant note:</strong> {section.officiant_note}
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>

                    <div className={styles.suggestions}>
                        <div className={styles.chip}>
                            <strong>Attire:</strong> {result.attire_suggestion}
                        </div>
                        <div className={styles.chip}>
                            <strong>Food:</strong> {result.food_suggestion}
                        </div>
                        <div className={styles.chip}>
                            <strong>Music:</strong> {result.music_suggestion}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default CultureBlender;
