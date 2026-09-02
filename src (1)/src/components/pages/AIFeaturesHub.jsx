import React from "react";
import { Link } from "react-router-dom";
import styles from "./AIFeaturesHub.module.css";
import { FaMagic, FaHeart, FaBalanceScale, FaClock, FaRobot } from "react-icons/fa";

const AIFeaturesHub = () => {
    const features = [
        {
            id: 1,
            title: "Shaadi AI Chat",
            description: "Get personalized vendor recommendations through natural conversation",
            icon: <FaRobot />,
            path: "/shaadi-ai",
            color: "#3b82f6"
        },
        {
            id: 2,
            title: "Wedding Personality Quiz",
            description: "Discover your unique wedding style and get personalized recommendations",
            icon: <FaHeart />,
            path: "/personality-quiz",
            color: "#ec4899"
        },
        {
            id: 3,
            title: "Multi-Culture Blender",
            description: "Blend two cultures into a beautiful, harmonious ceremony",
            icon: <FaMagic />,
            path: "/culture-blender",
            color: "#9333ea"
        },
        {
            id: 4,
            title: "Conflict Resolver",
            description: "Find common ground with AI-powered mediation for wedding decisions",
            icon: <FaBalanceScale />,
            path: "/conflict-resolver",
            color: "#059669"
        },
        {
            id: 5,
            title: "Timeline Generator",
            description: "Create a perfectly timed wedding day schedule with AI assistance",
            icon: <FaClock />,
            path: "/timeline-generator",
            color: "#f59e0b"
        }
    ];

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <h1>AI Wedding Planning Tools</h1>
                <p>Powered by Llama 3 70B — Your intelligent wedding planning assistant</p>
            </div>

            <div className={styles.grid}>
                {features.map(feature => (
                    <Link
                        key={feature.id}
                        to={feature.path}
                        className={styles.card}
                        style={{ borderTopColor: feature.color }}
                    >
                        <div className={styles.cardIcon} style={{ color: feature.color }}>
                            {feature.icon}
                        </div>
                        <h3>{feature.title}</h3>
                        <p>{feature.description}</p>
                        <div className={styles.cardFooter}>
                            <span style={{ color: feature.color }}>Try it now →</span>
                        </div>
                    </Link>
                ))}
            </div>

            <div className={styles.infoBox}>
                <h3>💡 Pro Tip</h3>
                <p>
                    Start with the <strong>Wedding Personality Quiz</strong> to create your couple profile. 
                    This will personalize all other AI features to match your unique style!
                </p>
            </div>
        </div>
    );
};

export default AIFeaturesHub;
