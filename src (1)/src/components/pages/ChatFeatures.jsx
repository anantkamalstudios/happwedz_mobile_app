import React, { useState } from "react";
import axios from "../../services/api/axiosInstance";
import styles from "./ChatFeatures.module.css";
import { FaHeart, FaMagic, FaBalanceScale, FaClock, FaSpinner, FaCheckCircle } from "react-icons/fa";

// ============ PERSONALITY QUIZ ============
export const PersonalityQuizInline = ({ onComplete }) => {
    const QUESTIONS = [
        { id: 1, question: "Wedding Scale", option1: "Intimate (30–60 guests)", option2: "Grand (200+ guests)" },
        { id: 2, question: "Formality", option1: "Casual/barefoot", option2: "Black tie" },
        { id: 3, question: "Emotion", option1: "Romantic & heartfelt", option2: "Fun & wild" },
        { id: 4, question: "Culture", option1: "Full traditional rituals", option2: "Modern selective" },
        { id: 5, question: "Pace", option1: "Relaxed & flowing", option2: "Perfectly choreographed" },
        { id: 6, question: "Focus", option1: "Ceremony is main event", option2: "Reception is main event" },
        { id: 7, question: "Vibe", option1: "Timeless & classic", option2: "Unique & unexpected" }
    ];

    const [partner1Answers, setPartner1Answers] = useState(Array(7).fill(null));
    const [partner2Answers, setPartner2Answers] = useState(Array(7).fill(null));
    const [loading, setLoading] = useState(false);

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

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            const response = await axios.post("/ai/personality-quiz", {
                partner1Answers,
                partner2Answers
            });

            localStorage.setItem('wedding_personality_profile', JSON.stringify(response.data));
            onComplete(response.data);
        } catch (err) {
            console.error("Personality Quiz error:", err);
            onComplete({ error: "Couldn't process that — try again" });
        } finally {
            setLoading(false);
        }
    };

    const allAnswered = partner1Answers.every(a => a !== null) && partner2Answers.every(a => a !== null);

    return (
        <div className={styles.featureCard}>
            <div className={styles.featureHeader}>
                <FaHeart className={styles.icon} />
                <h3>Personality Quiz</h3>
            </div>
            
            <form onSubmit={handleSubmit} className={styles.quizForm}>
                {QUESTIONS.map((q, idx) => (
                    <div key={q.id} className={styles.questionRow}>
                        <div className={styles.questionLabel}>Q{q.id}: {q.question}</div>
                        <div className={styles.answersGrid}>
                            <div className={styles.partnerCol}>
                                <span className={styles.partnerLabel}>Partner 1</span>
                                <label className={`${styles.option} ${partner1Answers[idx] === 0 ? styles.selected : ''}`}>
                                    <input type="radio" name={`p1_q${q.id}`} checked={partner1Answers[idx] === 0} onChange={() => handleAnswer(1, idx, 0)} />
                                    <span>{q.option1}</span>
                                </label>
                                <label className={`${styles.option} ${partner1Answers[idx] === 1 ? styles.selected : ''}`}>
                                    <input type="radio" name={`p1_q${q.id}`} checked={partner1Answers[idx] === 1} onChange={() => handleAnswer(1, idx, 1)} />
                                    <span>{q.option2}</span>
                                </label>
                            </div>
                            <div className={styles.partnerCol}>
                                <span className={styles.partnerLabel}>Partner 2</span>
                                <label className={`${styles.option} ${partner2Answers[idx] === 0 ? styles.selected : ''}`}>
                                    <input type="radio" name={`p2_q${q.id}`} checked={partner2Answers[idx] === 0} onChange={() => handleAnswer(2, idx, 0)} />
                                    <span>{q.option1}</span>
                                </label>
                                <label className={`${styles.option} ${partner2Answers[idx] === 1 ? styles.selected : ''}`}>
                                    <input type="radio" name={`p2_q${q.id}`} checked={partner2Answers[idx] === 1} onChange={() => handleAnswer(2, idx, 1)} />
                                    <span>{q.option2}</span>
                                </label>
                            </div>
                        </div>
                    </div>
                ))}

                <button type="submit" className={styles.submitBtn} disabled={!allAnswered || loading}>
                    {loading ? <><FaSpinner className={styles.spinner} /> Analyzing...</> : "Get Your Profile"}
                </button>
            </form>
        </div>
    );
};

// ============ CULTURE BLENDER ============
export const CultureBlenderInline = ({ onComplete }) => {
    const CULTURES = [
        "Indian (Hindu)", "Indian (Muslim)", "Indian (Sikh)", "Indian (Christian)",
        "Chinese", "Japanese", "Korean", "Thai", "Vietnamese",
        "Mexican", "Brazilian", "Italian", "French", "Spanish", "Greek",
        "British", "Irish", "German", "Nigerian", "Lebanese", "Turkish"
    ];

    const [culture1, setCulture1] = useState("");
    const [culture2, setCulture2] = useState("");
    const [ceremonyType, setCeremonyType] = useState("");
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            const savedProfile = localStorage.getItem('wedding_personality_profile');
            const recommendationsLens = savedProfile ? JSON.parse(savedProfile).recommendations_lens : null;

            const response = await axios.post("/ai/culture-blender", {
                culture1,
                culture2,
                ceremonyType,
                partner1Priorities: { rituals: 2, attire: 2, food: 2, music: 2, venueStyle: 2 },
                partner2Priorities: { rituals: 2, attire: 2, food: 2, music: 2, venueStyle: 2 },
                recommendationsLens
            });

            onComplete(response.data);
        } catch (err) {
            console.error("Culture Blender error:", err);
            onComplete({ error: "Couldn't process that — try again" });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className={styles.featureCard}>
            <div className={styles.featureHeader}>
                <FaMagic className={styles.icon} />
                <h3>Culture Blender</h3>
            </div>
            
            <form onSubmit={handleSubmit} className={styles.blenderForm}>
                <div className={styles.formRow}>
                    <div className={styles.formField}>
                        <label>Partner 1 Culture</label>
                        <select value={culture1} onChange={(e) => setCulture1(e.target.value)} required>
                            <option value="">Select culture</option>
                            {CULTURES.map(c => <option key={c} value={c}>{c}</option>)}
                        </select>
                    </div>
                    <div className={styles.formField}>
                        <label>Partner 2 Culture</label>
                        <select value={culture2} onChange={(e) => setCulture2(e.target.value)} required>
                            <option value="">Select culture</option>
                            {CULTURES.map(c => <option key={c} value={c}>{c}</option>)}
                        </select>
                    </div>
                </div>

                <div className={styles.formField}>
                    <label>Ceremony Type</label>
                    <div className={styles.radioGroup}>
                        {["Religious", "Civil", "Symbolic"].map(type => (
                            <label key={type} className={styles.radioOption}>
                                <input type="radio" name="ceremonyType" value={type} checked={ceremonyType === type} onChange={(e) => setCeremonyType(e.target.value)} required />
                                <span>{type}</span>
                            </label>
                        ))}
                    </div>
                </div>

                <button type="submit" className={styles.submitBtn} disabled={!culture1 || !culture2 || !ceremonyType || loading}>
                    {loading ? <><FaSpinner className={styles.spinner} /> Blending...</> : "Blend Cultures"}
                </button>
            </form>
        </div>
    );
};

// ============ CONFLICT RESOLVER ============
export const ConflictResolverInline = ({ onComplete }) => {
    const TOPICS = ["Venue", "Guest list size", "Budget split", "Date", "Décor", "Food", "Specific guests", "Other"];

    const [topic, setTopic] = useState("");
    const [partner1Input, setPartner1Input] = useState("");
    const [partner2Input, setPartner2Input] = useState("");
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            const savedProfile = localStorage.getItem('wedding_personality_profile');
            const recommendationsLens = savedProfile ? JSON.parse(savedProfile).recommendations_lens : null;

            const response = await axios.post("/ai/conflict-resolver", {
                topic,
                partner1Input,
                partner2Input,
                recommendationsLens
            });

            onComplete(response.data);
        } catch (err) {
            console.error("Conflict Resolver error:", err);
            onComplete({ error: "Couldn't process that — try again" });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className={styles.featureCard}>
            <div className={styles.featureHeader}>
                <FaBalanceScale className={styles.icon} />
                <h3>Conflict Resolver</h3>
            </div>
            
            <form onSubmit={handleSubmit} className={styles.resolverForm}>
                <div className={styles.formField}>
                    <label>Conflict Topic</label>
                    <select value={topic} onChange={(e) => setTopic(e.target.value)} required>
                        <option value="">Select topic</option>
                        {TOPICS.map(t => <option key={t} value={t}>{t}</option>)}
                    </select>
                </div>

                <div className={styles.formField}>
                    <label>Partner 1's Position</label>
                    <textarea value={partner1Input} onChange={(e) => setPartner1Input(e.target.value)} placeholder="Explain your perspective..." rows={3} required />
                </div>

                <div className={styles.formField}>
                    <label>Partner 2's Position</label>
                    <textarea value={partner2Input} onChange={(e) => setPartner2Input(e.target.value)} placeholder="Explain your perspective..." rows={3} required />
                </div>

                <button type="submit" className={styles.submitBtn} disabled={!topic || !partner1Input.trim() || !partner2Input.trim() || loading}>
                    {loading ? <><FaSpinner className={styles.spinner} /> Analyzing...</> : "Find Solutions"}
                </button>
            </form>
        </div>
    );
};

// ============ TIMELINE GENERATOR ============
export const TimelineGeneratorInline = ({ onComplete }) => {
    const AVAILABLE_EVENTS = [
        "Mehendi Ceremony",
        "Sangeet Night",
        "Haldi Ceremony",
        "Wedding Ceremony",
        "Cocktail Hour",
        "Reception",
        "Baraat Procession",
        "Pheras/Vows",
        "Couple Photography",
        "Family Photography",
        "Dinner Service",
        "Cake Cutting",
        "First Dance",
        "Entertainment/Performances"
    ];

    const [startTime, setStartTime] = useState("10:00");
    const [selectedEvents, setSelectedEvents] = useState([]);
    const [travelMins, setTravelMins] = useState(0);
    const [constraints, setConstraints] = useState("");
    const [loading, setLoading] = useState(false);

    const handleEventToggle = (event) => {
        if (selectedEvents.includes(event)) {
            setSelectedEvents(selectedEvents.filter(e => e !== event));
        } else {
            setSelectedEvents([...selectedEvents, event]);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            const savedProfile = localStorage.getItem('wedding_personality_profile');
            const recommendationsLens = savedProfile ? JSON.parse(savedProfile).recommendations_lens : null;

            const response = await axios.post("/ai/timeline-generator", {
                startTime,
                selectedEvents,
                travelMins: parseInt(travelMins) || 0,
                constraints: constraints.trim() || null,
                recommendationsLens
            });

            onComplete(response.data);
        } catch (err) {
            console.error("Timeline Generator error:", err);
            onComplete({ error: "Couldn't process that — try again" });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className={styles.featureCard}>
            <div className={styles.featureHeader}>
                <FaClock className={styles.icon} />
                <h3>Timeline Generator</h3>
            </div>
            
            <form onSubmit={handleSubmit} className={styles.timelineForm}>
                <div className={styles.formField}>
                    <label>Ceremony Start Time</label>
                    <input 
                        type="time" 
                        value={startTime} 
                        onChange={(e) => setStartTime(e.target.value)} 
                        required 
                    />
                </div>

                <div className={styles.formField}>
                    <label>Select Events to Include</label>
                    <div className={styles.checkboxGrid}>
                        {AVAILABLE_EVENTS.map((event) => (
                            <label key={event} className={styles.checkboxLabel}>
                                <input
                                    type="checkbox"
                                    checked={selectedEvents.includes(event)}
                                    onChange={() => handleEventToggle(event)}
                                />
                                <span>{event}</span>
                            </label>
                        ))}
                    </div>
                </div>

                <div className={styles.formField}>
                    <label>Travel Time Between Venues (minutes)</label>
                    <input 
                        type="number" 
                        value={travelMins} 
                        onChange={(e) => setTravelMins(e.target.value)} 
                        min="0"
                        max="120"
                        placeholder="0"
                    />
                </div>

                <div className={styles.formField}>
                    <label>Special Constraints (optional)</label>
                    <textarea 
                        value={constraints} 
                        onChange={(e) => setConstraints(e.target.value)} 
                        placeholder="e.g., Must end by 11 PM, Need 30 min break after ceremony, etc." 
                        rows={2}
                    />
                </div>

                <button type="submit" className={styles.submitBtn} disabled={selectedEvents.length === 0 || loading}>
                    {loading ? <><FaSpinner className={styles.spinner} /> Generating...</> : "Generate Timeline"}
                </button>
            </form>
        </div>
    );
};

// ============ RESULT RENDERERS ============
export const PersonalityQuizResult = ({ result }) => (
    <div className={styles.resultCard}>
        <div className={styles.resultHeader}>
            <FaCheckCircle className={styles.successIcon} />
            <h3>🎉 {result.profile_name}</h3>
        </div>
        <p className={styles.description}>{result.description}</p>
        
        {result.traits && (
            <div className={styles.traits}>
                {result.traits.map((trait, idx) => (
                    <span key={idx} className={styles.trait}>{trait}</span>
                ))}
            </div>
        )}

        <div className={styles.details}>
            <div className={styles.detailItem}>
                <strong>🏛️ Venue Style:</strong> {result.venue_style}
            </div>
            <div className={styles.detailItem}>
                <strong>🎨 Decor Style:</strong> {result.decor_style}
            </div>
        </div>

        {result.mismatch_alert && (
            <div className={styles.alert}>
                <strong>💡 Note:</strong> {result.mismatch_alert}
            </div>
        )}

        <div className={styles.lens}>
            <strong>🎯 AI Planning Lens:</strong>
            <p>{result.recommendations_lens}</p>
        </div>
    </div>
);

export const CultureBlenderResult = ({ result }) => (
    <div className={styles.resultCard}>
        <h3>✨ Blended Ceremony</h3>
        
        {result.ceremony_sections && result.ceremony_sections.map((section, idx) => (
            <div key={idx} className={styles.ceremonySection}>
                <div className={styles.sectionHeader}>
                    <h4>{section.name}</h4>
                    <span className={styles.badge}>{section.origin}</span>
                    <span className={styles.duration}>⏱️ {section.duration_mins} mins</span>
                </div>
                <p>{section.description}</p>
                {section.guest_explanation && <p className={styles.note}>👥 {section.guest_explanation}</p>}
            </div>
        ))}

        <div className={styles.suggestions}>
            <div><strong>👗 Attire:</strong> {result.attire_suggestion}</div>
            <div><strong>🍽️ Food:</strong> {result.food_suggestion}</div>
            <div><strong>🎵 Music:</strong> {result.music_suggestion}</div>
        </div>
    </div>
);

export const ConflictResolverResult = ({ result }) => (
    <div className={styles.resultCard}>
        <div className={styles.reframe}>
            <strong>💡 Reframe:</strong>
            <p>{result.reframe}</p>
        </div>

        <div className={styles.needs}>
            <div className={styles.need}>
                <strong>Partner 1's Need:</strong> {result.partner1_real_need}
            </div>
            <div className={styles.need}>
                <strong>Partner 2's Need:</strong> {result.partner2_real_need}
            </div>
        </div>

        <h4>Resolution Options:</h4>
        {result.options && result.options.map((option, idx) => (
            <div key={idx} className={`${styles.optionCard} ${option.ai_recommended ? styles.recommended : ''}`}>
                {option.ai_recommended && <span className={styles.recommendedBadge}>✨ AI Recommended</span>}
                <h5>{option.title}</h5>
                <p>{option.description}</p>
                <div className={styles.tradeoffs}>
                    <small>P1 gives up: {option.partner1_gives_up}</small>
                    <small>P2 gives up: {option.partner2_gives_up}</small>
                </div>
            </div>
        ))}
    </div>
);

export const TimelineGeneratorResult = ({ result }) => {
    // Handle if result is an array (direct timeline) or object with timeline property
    const timeline = Array.isArray(result) ? result : (result.timeline || []);
    
    if (!timeline || timeline.length === 0) {
        return (
            <div className={styles.resultCard}>
                <h3>📅 Your Wedding Timeline</h3>
                <p>No timeline data available.</p>
            </div>
        );
    }

    return (
        <div className={styles.resultCard}>
            <h3>📅 Your Wedding Timeline</h3>
            <div className={styles.timelineContainer}>
                {timeline.map((item, idx) => (
                    <div key={idx} className={`${styles.timelineItem} ${item.warning ? styles.timelineWarning : ''}`}>
                        <div className={styles.timelineTime}>
                            <strong>{item.time}</strong>
                            <span className={styles.duration}>{item.duration_mins} min</span>
                        </div>
                        <div className={styles.timelineContent}>
                            <div className={styles.timelineHeader}>
                                <h4>{item.title}</h4>
                                <span className={styles.timelineType}>{item.type}</span>
                            </div>
                            {item.notes && <p className={styles.timelineNotes}>{item.notes}</p>}
                            {item.warning && (
                                <div className={styles.timelineAlert}>
                                    ⚠️ This event may be rushed - consider adjusting timing
                                </div>
                            )}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};
