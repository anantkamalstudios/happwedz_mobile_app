import React, { useState } from "react";
import axios from "../../services/api/axiosInstance";
import styles from "./AIFeatures.module.css";
import { FaClock, FaSpinner, FaFilter } from "react-icons/fa";

const EVENTS = [
    "Bridal prep",
    "Haldi",
    "Mehendi",
    "Baraat",
    "Jaimala",
    "Pheras",
    "Church ceremony",
    "Cocktail hour",
    "Lunch",
    "Dinner",
    "Reception",
    "Cake cutting",
    "First dance",
    "Farewell"
];

const VIEWS = [
    { id: "all", label: "All Events", filter: null },
    { id: "couple", label: "Couple View", filter: "ceremony" },
    { id: "photographer", label: "Photographer View", filter: ["ceremony", "photography"] },
    { id: "mc", label: "MC View", filter: ["entertainment", "ceremony"] }
];

const TYPE_COLORS = {
    ceremony: "#9333ea",
    photography: "#14b8a6",
    food: "#f59e0b",
    travel: "#6b7280",
    buffer: "#6b7280",
    entertainment: "#f97316"
};

const TimelineGenerator = () => {
    const [startTime, setStartTime] = useState("10:00");
    const [selectedEvents, setSelectedEvents] = useState([]);
    const [travelMins, setTravelMins] = useState(30);
    const [constraints, setConstraints] = useState("");
    const [result, setResult] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [activeView, setActiveView] = useState("all");

    const toggleEvent = (event) => {
        setSelectedEvents(prev =>
            prev.includes(event) ? prev.filter(e => e !== event) : [...prev, event]
        );
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        setLoading(true);

        try {
            // Get recommendations_lens from localStorage if available
            const savedProfile = localStorage.getItem('wedding_personality_profile');
            const recommendationsLens = savedProfile ? JSON.parse(savedProfile).recommendations_lens : null;

            const response = await axios.post("/ai/timeline-generator", {
                startTime,
                selectedEvents,
                travelMins,
                constraints,
                recommendationsLens
            });

            setResult(response.data);
        } catch (err) {
            console.error("Timeline Generator error:", err);
            setError("Couldn't process that — try again");
        } finally {
            setLoading(false);
        }
    };

    const getFilteredTimeline = () => {
        if (!result) return [];
        
        const view = VIEWS.find(v => v.id === activeView);
        if (!view || !view.filter) return result;

        if (Array.isArray(view.filter)) {
            return result.filter(item => view.filter.includes(item.type));
        }
        return result.filter(item => item.type === view.filter);
    };

    const canSubmit = startTime && selectedEvents.length > 0;

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <FaClock className={styles.headerIcon} />
                <h1>Timeline Generator</h1>
                <p>Create a perfectly timed wedding day schedule</p>
            </div>

            <form onSubmit={handleSubmit} className={styles.form}>
                <div className={styles.field}>
                    <label>Ceremony Start Time</label>
                    <input
                        type="time"
                        value={startTime}
                        onChange={(e) => setStartTime(e.target.value)}
                        required
                    />
                </div>

                <div className={styles.field}>
                    <label>Events to Include</label>
                    <div className={styles.eventsGrid}>
                        {EVENTS.map(event => (
                            <label key={event} className={styles.checkboxLabel}>
                                <input
                                    type="checkbox"
                                    checked={selectedEvents.includes(event)}
                                    onChange={() => toggleEvent(event)}
                                />
                                {event}
                            </label>
                        ))}
                    </div>
                </div>

                <div className={styles.field}>
                    <label>Travel Time Between Venues (minutes)</label>
                    <input
                        type="number"
                        value={travelMins}
                        onChange={(e) => setTravelMins(parseInt(e.target.value))}
                        min="0"
                        max="120"
                    />
                </div>

                <div className={styles.field}>
                    <label>Hard Constraints (Optional)</label>
                    <textarea
                        value={constraints}
                        onChange={(e) => setConstraints(e.target.value)}
                        placeholder="E.g., Must finish by 11 PM, Lunch must be at 1 PM..."
                        rows={3}
                    />
                </div>

                <button type="submit" className={styles.submitBtn} disabled={!canSubmit || loading}>
                    {loading ? <><FaSpinner className={styles.spinner} /> Generating...</> : "Generate Timeline"}
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
                    <div className={styles.viewTabs}>
                        {VIEWS.map(view => (
                            <button
                                key={view.id}
                                className={`${styles.viewTab} ${activeView === view.id ? styles.activeTab : ''}`}
                                onClick={() => setActiveView(view.id)}
                            >
                                <FaFilter /> {view.label}
                            </button>
                        ))}
                    </div>

                    <div className={styles.timeline}>
                        {getFilteredTimeline().map((item, idx) => (
                            <div
                                key={idx}
                                className={`${styles.timelineItem} ${item.warning ? styles.warning : ''}`}
                                style={{ borderLeftColor: TYPE_COLORS[item.type] || '#6b7280' }}
                            >
                                <div className={styles.timelineTime}>{item.time}</div>
                                <div className={styles.timelineContent}>
                                    <div className={styles.timelineHeader}>
                                        <h4>{item.title}</h4>
                                        <span className={styles.typeBadge} style={{ backgroundColor: TYPE_COLORS[item.type] }}>
                                            {item.type}
                                        </span>
                                    </div>
                                    <div className={styles.timelineMeta}>
                                        <span>⏱️ {item.duration_mins} mins</span>
                                        {item.warning && <span className={styles.warningBadge}>⚠️ Tight timing</span>}
                                    </div>
                                    {item.notes && <p className={styles.timelineNotes}>{item.notes}</p>}
                                </div>
                            </div>
                        ))}
                    </div>

                    <div className={styles.legend}>
                        <h4>Color Legend:</h4>
                        <div className={styles.legendItems}>
                            {Object.entries(TYPE_COLORS).map(([type, color]) => (
                                <div key={type} className={styles.legendItem}>
                                    <span className={styles.legendColor} style={{ backgroundColor: color }}></span>
                                    {type}
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default TimelineGenerator;
