import React, { useState } from "react";
import axios from "../../services/api/axiosInstance";
import styles from "./AIFeatures.module.css";
import { FaBalanceScale, FaSpinner, FaLock } from "react-icons/fa";

const TOPICS = [
    "Venue",
    "Guest list size",
    "Budget split",
    "Date",
    "Décor",
    "Food",
    "Specific guests",
    "Other"
];

const ConflictResolver = () => {
    const [topic, setTopic] = useState("");
    const [partner1Input, setPartner1Input] = useState("");
    const [partner2Input, setPartner2Input] = useState("");
    const [result, setResult] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [decisionsLog, setDecisionsLog] = useState([]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        setLoading(true);

        try {
            // Get recommendations_lens from localStorage if available
            const savedProfile = localStorage.getItem('wedding_personality_profile');
            const recommendationsLens = savedProfile ? JSON.parse(savedProfile).recommendations_lens : null;

            const response = await axios.post("/ai/conflict-resolver", {
                topic,
                partner1Input,
                partner2Input,
                recommendationsLens
            });

            setResult(response.data);
        } catch (err) {
            console.error("Conflict Resolver error:", err);
            setError("Couldn't process that — try again");
        } finally {
            setLoading(false);
        }
    };

    const lockDecision = (option) => {
        const decision = {
            topic,
            chosenOption: option,
            timestamp: new Date().toISOString()
        };
        setDecisionsLog(prev => [...prev, decision]);
        
        // Save to localStorage
        const saved = localStorage.getItem('wedding_decisions_log');
        const log = saved ? JSON.parse(saved) : [];
        log.push(decision);
        localStorage.setItem('wedding_decisions_log', JSON.stringify(log));

        alert(`Decision locked: ${option.title}`);
    };

    const canSubmit = topic && partner1Input.trim() && partner2Input.trim();

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <FaBalanceScale className={styles.headerIcon} />
                <h1>Couple Conflict Resolver</h1>
                <p>Find common ground with AI-powered mediation</p>
            </div>

            <form onSubmit={handleSubmit} className={styles.form}>
                <div className={styles.field}>
                    <label>Conflict Topic</label>
                    <select value={topic} onChange={(e) => setTopic(e.target.value)} required>
                        <option value="">Select topic</option>
                        {TOPICS.map(t => <option key={t} value={t}>{t}</option>)}
                    </select>
                </div>

                <div className={styles.field}>
                    <label>Partner 1's Position (Private)</label>
                    <textarea
                        value={partner1Input}
                        onChange={(e) => setPartner1Input(e.target.value)}
                        placeholder="Explain your perspective..."
                        rows={4}
                        required
                    />
                </div>

                <div className={styles.field}>
                    <label>Partner 2's Position (Private)</label>
                    <textarea
                        value={partner2Input}
                        onChange={(e) => setPartner2Input(e.target.value)}
                        placeholder="Explain your perspective..."
                        rows={4}
                        required
                    />
                </div>

                <button type="submit" className={styles.submitBtn} disabled={!canSubmit || loading}>
                    {loading ? <><FaSpinner className={styles.spinner} /> Analyzing...</> : "Find Solutions"}
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
                    <div className={styles.reframeCard}>
                        <h3>💡 Reframe</h3>
                        <p>{result.reframe}</p>
                    </div>

                    <div className={styles.needsSection}>
                        <div className={styles.needCard}>
                            <h4>Partner 1's Real Need</h4>
                            <p>{result.partner1_real_need}</p>
                        </div>
                        <div className={styles.needCard}>
                            <h4>Partner 2's Real Need</h4>
                            <p>{result.partner2_real_need}</p>
                        </div>
                    </div>

                    <div className={styles.optionsSection}>
                        <h3>Resolution Options</h3>
                        {result.options && result.options.map((option, idx) => (
                            <div 
                                key={idx} 
                                className={`${styles.optionCard} ${option.ai_recommended ? styles.recommended : ''}`}
                            >
                                {option.ai_recommended && <span className={styles.recommendedBadge}>AI Recommended</span>}
                                <h4>{option.title}</h4>
                                <p>{option.description}</p>
                                
                                <div className={styles.tradeoffs}>
                                    <div className={styles.tradeoff}>
                                        <strong>Partner 1 gives up:</strong> {option.partner1_gives_up}
                                    </div>
                                    <div className={styles.tradeoff}>
                                        <strong>Partner 2 gives up:</strong> {option.partner2_gives_up}
                                    </div>
                                </div>

                                <button 
                                    className={styles.lockBtn}
                                    onClick={() => lockDecision(option)}
                                >
                                    <FaLock /> Lock This Decision
                                </button>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {decisionsLog.length > 0 && (
                <div className={styles.decisionsLog}>
                    <h3>Locked Decisions</h3>
                    {decisionsLog.map((decision, idx) => (
                        <div key={idx} className={styles.decisionItem}>
                            <strong>{decision.topic}:</strong> {decision.chosenOption.title}
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default ConflictResolver;
