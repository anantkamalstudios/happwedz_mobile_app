import React, { useState, useEffect } from "react";
import {
  Heart,
  Users,
  Shield,
  Star,
  CheckCircle,
  ArrowRight,
  Play,
  MessageCircle,
  UserCheck,
} from "lucide-react";

const Home = () => {
  const [currentTestimonial, setCurrentTestimonial] = useState(0);
  const [stats, setStats] = useState({
    totalMembers: 2500000,
    successStories: 50000,
    dailyMatches: 15000,
    verifiedProfiles: 95,
  });

  const testimonials = [
    {
      id: 1,
      name: "Ravi & Priya",
      story:
        "We found each other through SoulMate Connect and got married last year. It was the best decision we ever made!",
      image:
        "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=300&h=200&fit=crop",
      location: "Mumbai, Maharashtra",
    },
    {
      id: 2,
      name: "Amit & Sneha",
      story:
        "Thanks to the advanced matching algorithm, we found our perfect match. We're celebrating our first anniversary!",
      image:
        "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=300&h=200&fit=crop",
      location: "Bangalore, Karnataka",
    },
    {
      id: 3,
      name: "Vikram & Anjali",
      story:
        "The platform's security and verification process gave us confidence. We're now happily married with a beautiful family.",
      image:
        "https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=300&h=200&fit=crop",
      location: "Delhi, NCR",
    },
  ];

  const features = [
    {
      icon: Shield,
      title: "100% Verified Profiles",
      description:
        "All profiles are manually verified to ensure authenticity and safety",
    },
    {
      icon: UserCheck,
      title: "Advanced Matching",
      description:
        "AI-powered matching algorithm to find your perfect life partner",
    },
    {
      icon: MessageCircle,
      title: "Secure Communication",
      description:
        "End-to-end encrypted messaging for safe and private conversations",
    },
    {
      icon: Star,
      title: "Premium Experience",
      description:
        "Ad-free browsing with premium features for serious matrimony seekers",
    },
  ];

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTestimonial((prev) => (prev + 1) % testimonials.length);
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="matrimonial">
      <div className="matrimony-unique-body mtu-root">
        {/* Hero Section */}
        <section
          style={{
            background: "var(--mtu-gradient-primary)",
            color: "var(--mtu-white)",
            padding: "4rem 2rem",
            textAlign: "center",
            position: "relative",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              maxWidth: "1200px",
              margin: "0 auto",
              position: "relative",
              zIndex: 2,
            }}
          >
            <h1
              style={{
                fontSize: "3.5rem",
                fontWeight: "700",
                marginBottom: "1rem",
                textShadow: "2px 2px 4px rgba(0,0,0,0.3)",
              }}
            >
              Find Your Perfect Life Partner
            </h1>
            <p
              style={{
                fontSize: "1.3rem",
                marginBottom: "2rem",
                opacity: 0.9,
                maxWidth: "600px",
                margin: "0 auto 2rem",
              }}
            >
              Join millions of happy couples who found their soulmate through
              our trusted matrimonial platform
            </p>
            <div
              style={{
                display: "flex",
                gap: "1rem",
                justifyContent: "center",
                flexWrap: "wrap",
              }}
            >
              <button
                className="mtu-btn"
                style={{
                  background: "var(--mtu-white)",
                  color: "var(--mtu-primary-pink)",
                  padding: "1rem 2rem",
                  fontSize: "1.1rem",
                  fontWeight: "600",
                  border: "none",
                  borderRadius: "0.5rem",
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  display: "flex",
                  alignItems: "center",
                  gap: "0.5rem",
                }}
              >
                <Heart size={20} />
                Start Your Journey
              </button>
              <button
                className="mtu-btn"
                style={{
                  background: "transparent",
                  color: "var(--mtu-white)",
                  padding: "1rem 2rem",
                  fontSize: "1.1rem",
                  fontWeight: "600",
                  border: "2px solid var(--mtu-white)",
                  borderRadius: "0.5rem",
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  display: "flex",
                  alignItems: "center",
                  gap: "0.5rem",
                }}
              >
                <Play size={20} />
                Watch Success Stories
              </button>
            </div>
          </div>

          {/* Floating Hearts Animation */}
          <div
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              opacity: 0.1,
              overflow: "hidden",
            }}
          >
            {[...Array(5)].map((_, i) => (
              <Heart
                key={i}
                size={30}
                style={{
                  position: "absolute",
                  left: `${20 + i * 15}%`,
                  top: `${20 + i * 10}%`,
                  animation: `mtu-pulse ${2 + i * 0.5}s infinite alternate`,
                }}
              />
            ))}
          </div>
        </section>

        {/* Call to Action Section */}
        <section
          style={{
            padding: "4rem 2rem",
            background: "var(--mtu-gradient-primary)",
            color: "var(--mtu-white)",
            textAlign: "center",
          }}
        >
          <div style={{ maxWidth: "800px", margin: "0 auto" }}>
            <h2
              style={{
                fontSize: "2.5rem",
                fontWeight: "700",
                marginBottom: "1rem",
              }}
            >
              Ready to Find Your Soulmate?
            </h2>
            <p
              style={{
                fontSize: "1.2rem",
                marginBottom: "2rem",
                opacity: 0.9,
              }}
            >
              Join thousands of happy couples who found love through our
              platform. Your perfect match is just a click away!
            </p>
            <div
              style={{
                display: "flex",
                gap: "1rem",
                justifyContent: "center",
                flexWrap: "wrap",
              }}
            >
              <button
                className="mtu-btn"
                style={{
                  background: "var(--mtu-white)",
                  color: "var(--mtu-primary-pink)",
                  padding: "1rem 2rem",
                  fontSize: "1.1rem",
                  fontWeight: "600",
                  border: "none",
                  borderRadius: "0.5rem",
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  display: "flex",
                  alignItems: "center",
                  gap: "0.5rem",
                }}
              >
                Register Free Now
                <ArrowRight size={20} />
              </button>
              <button
                className="mtu-btn"
                style={{
                  background: "transparent",
                  color: "var(--mtu-white)",
                  padding: "1rem 2rem",
                  fontSize: "1.1rem",
                  fontWeight: "600",
                  border: "2px solid var(--mtu-white)",
                  borderRadius: "0.5rem",
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                }}
              >
                Browse Profiles
              </button>
            </div>
          </div>
        </section>

        {/* How It Works Section */}
        <section
          style={{ padding: "4rem 2rem", background: "var(--mtu-light-gray)" }}
        >
          <div style={{ maxWidth: "1200px", margin: "0 auto" }}>
            <div style={{ textAlign: "center", marginBottom: "3rem" }}>
              <h2
                style={{
                  fontSize: "2.5rem",
                  fontWeight: "700",
                  color: "var(--mtu-dark-gray)",
                  marginBottom: "1rem",
                }}
              >
                How It Works
              </h2>
              <p
                style={{
                  fontSize: "1.1rem",
                  color: "var(--mtu-gray)",
                }}
              >
                Simple steps to find your perfect life partner
              </p>
            </div>

            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))",
                gap: "2rem",
              }}
            >
              {[
                {
                  step: "1",
                  title: "Create Your Profile",
                  description:
                    "Sign up and create a detailed profile with your preferences and photos",
                  icon: UserCheck,
                },
                {
                  step: "2",
                  title: "Find Matches",
                  description:
                    "Browse through verified profiles or let our AI find compatible matches for you",
                  icon: Heart,
                },
                {
                  step: "3",
                  title: "Connect Safely",
                  description:
                    "Start conversations with your matches through our secure messaging platform",
                  icon: MessageCircle,
                },
                {
                  step: "4",
                  title: "Meet Your Soulmate",
                  description:
                    "Take the relationship forward and find your perfect life partner",
                  icon: Star,
                },
              ].map((item, index) => {
                const Icon = item.icon;
                return (
                  <div
                    key={index}
                    style={{
                      background: "var(--mtu-white)",
                      padding: "2rem",
                      borderRadius: "1rem",
                      textAlign: "center",
                      boxShadow: "var(--mtu-shadow)",
                      border: "1px solid var(--mtu-border-color)",
                      position: "relative",
                    }}
                  >
                    <div
                      style={{
                        position: "absolute",
                        top: "-15px",
                        left: "50%",
                        transform: "translateX(-50%)",
                        width: "40px",
                        height: "40px",
                        background: "var(--mtu-gradient-primary)",
                        borderRadius: "50%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "var(--mtu-white)",
                        fontWeight: "700",
                        fontSize: "1.2rem",
                      }}
                    >
                      {item.step}
                    </div>
                    <div
                      style={{
                        width: "80px",
                        height: "80px",
                        background: "var(--mtu-light-pink)",
                        borderRadius: "50%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        margin: "2rem auto 1.5rem",
                      }}
                    >
                      <Icon size={40} color="var(--mtu-primary-pink)" />
                    </div>
                    <h3
                      style={{
                        fontSize: "1.3rem",
                        fontWeight: "600",
                        color: "var(--mtu-dark-gray)",
                        marginBottom: "1rem",
                      }}
                    >
                      {item.title}
                    </h3>
                    <p
                      style={{
                        color: "var(--mtu-gray)",
                        lineHeight: "1.6",
                      }}
                    >
                      {item.description}
                    </p>
                  </div>
                );
              })}
            </div>
          </div>
        </section>

        {/* Trust Indicators */}
        <section style={{ padding: "3rem 2rem" }}>
          <div style={{ maxWidth: "1200px", margin: "0 auto" }}>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                gap: "2rem",
                textAlign: "center",
              }}
            >
              {[
                {
                  icon: Shield,
                  title: "Secure Platform",
                  subtitle: "SSL Encrypted",
                },
                {
                  icon: CheckCircle,
                  title: "Verified Profiles",
                  subtitle: "100% Authentic",
                },
                {
                  icon: Users,
                  title: "Trusted by Millions",
                  subtitle: "2.5M+ Members",
                },
                {
                  icon: Star,
                  title: "5-Star Rated",
                  subtitle: "Top Matrimonial App",
                },
              ].map((item, index) => {
                const Icon = item.icon;
                return (
                  <div
                    key={index}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      gap: "1rem",
                    }}
                  >
                    <Icon size={40} color="var(--mtu-primary-pink)" />
                    <div style={{ textAlign: "left" }}>
                      <h4
                        style={{
                          color: "var(--mtu-dark-gray)",
                          fontWeight: "600",
                          margin: 0,
                        }}
                      >
                        {item.title}
                      </h4>
                      <p
                        style={{
                          color: "var(--mtu-gray)",
                          fontSize: "0.9rem",
                          margin: 0,
                        }}
                      >
                        {item.subtitle}
                      </p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer
          style={{
            background: "var(--mtu-dark-gray)",
            color: "var(--mtu-white)",
            padding: "3rem 2rem 2rem",
          }}
        >
          <div style={{ maxWidth: "1200px", margin: "0 auto" }}>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))",
                gap: "2rem",
                marginBottom: "2rem",
              }}
            >
              <div>
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "0.5rem",
                    marginBottom: "1rem",
                  }}
                >
                  <Heart size={28} color="var(--mtu-secondary-pink)" />
                  <h3 style={{ fontSize: "1.5rem", fontWeight: "700" }}>
                    SoulMate Connect
                  </h3>
                </div>
                <p style={{ opacity: 0.8, lineHeight: "1.6" }}>
                  India's most trusted matrimonial platform connecting millions
                  of hearts worldwide.
                </p>
              </div>

              <div>
                <h4 style={{ marginBottom: "1rem", fontWeight: "600" }}>
                  Quick Links
                </h4>
                <ul style={{ listStyle: "none", padding: 0 }}>
                  {[
                    "Browse Profiles",
                    "Success Stories",
                    "Help & Support",
                    "Mobile App",
                  ].map((link) => (
                    <li key={link} style={{ marginBottom: "0.5rem" }}>
                      <a
                        href="#"
                        style={{
                          color: "var(--mtu-white)",
                          textDecoration: "none",
                          opacity: 0.8,
                          transition: "opacity 0.3s",
                        }}
                      >
                        {link}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>

              <div>
                <h4 style={{ marginBottom: "1rem", fontWeight: "600" }}>
                  Services
                </h4>
                <ul style={{ listStyle: "none", padding: 0 }}>
                  {[
                    "Premium Membership",
                    "Profile Verification",
                    "Assisted Service",
                    "Wedding Planning",
                  ].map((service) => (
                    <li key={service} style={{ marginBottom: "0.5rem" }}>
                      <a
                        href="#"
                        style={{
                          color: "var(--mtu-white)",
                          textDecoration: "none",
                          opacity: 0.8,
                          transition: "opacity 0.3",
                        }}
                      >
                        {service}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>

              <div>
                <h4 style={{ marginBottom: "1rem", fontWeight: "600" }}>
                  Contact Us
                </h4>
                <div style={{ opacity: 0.8 }}>
                  <p>📞 1800-XXX-XXXX</p>
                  <p>📧 support@soulmateconnect.com</p>
                  <p>📍 Mumbai, Maharashtra, India</p>
                </div>
              </div>
            </div>

            <div
              style={{
                borderTop: "1px solid rgba(255,255,255,0.2)",
                paddingTop: "2rem",
                textAlign: "center",
                opacity: 0.8,
              }}
            >
              <p>
                &copy; 2024 SoulMate Connect. All rights reserved. | Privacy
                Policy | Terms of Service
              </p>
            </div>
          </div>
        </footer>
      </div>
    </div>
  );
};

export default Home;
