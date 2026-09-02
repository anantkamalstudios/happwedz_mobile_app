import React, { useState, useEffect } from "react";
import {
  Heart,
  Users,
  MessageCircle,
  Star,
  Search,
  Filter,
  Bell,
  User,
  Settings,
  Home,
  Activity,
  UserCheck,
  Mail,
  Phone,
  MapPin,
  Calendar,
  Eye,
  ThumbsUp,
  X,
} from "lucide-react";

import { Link } from "react-router-dom";
import Matches from "./sections/Matches";
import ActivitySection from "./sections/Activity";
import MessagesSection from "./sections/Messages";
import InterestsSection from "./sections/Interests";
import AdvancedSearchSection from "./sections/AdvancedSearch";
import ProfileSection from "./sections/Profile";

const sampleProfiles = [
  {
    id: 1,
    name: "Priya Sharma",
    age: 26,
    location: "Mumbai, Maharashtra",
    education: "MBA Finance",
    profession: "Software Engineer",
    image:
      "https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=400&h=400&fit=crop&crop=face",
    status: "online",
    tags: ["Vegetarian", "Non-Smoker", "Yoga Enthusiast"],
    about:
      "Looking for a life partner who shares similar values and interests.",
  },
  {
    id: 2,
    name: "Ravi Kumar",
    age: 29,
    location: "Bangalore, Karnataka",
    education: "B.Tech IT",
    profession: "Data Scientist",
    image:
      "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face",
    status: "online",
    tags: ["Fitness", "Travel", "Music"],
    about:
      "Passionate about technology and looking for meaningful connections.",
  },
  {
    id: 3,
    name: "Anjali Patel",
    age: 24,
    location: "Ahmedabad, Gujarat",
    education: "CA",
    profession: "Chartered Accountant",
    image:
      "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face",
    status: "offline",
    tags: ["Books", "Classical Music", "Cooking"],
    about: "Family-oriented person seeking a caring and understanding partner.",
  },
  {
    id: 4,
    name: "Vikram Singh",
    age: 31,
    location: "Delhi, NCR",
    education: "MBBS",
    profession: "Doctor",
    image:
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face",
    status: "online",
    tags: ["Healthcare", "Social Work", "Reading"],
    about:
      "Dedicated medical professional looking for a supportive life partner.",
  },
  {
    id: 5,
    name: "Sneha Reddy",
    age: 27,
    location: "Hyderabad, Telangana",
    education: "M.Sc Physics",
    profession: "Research Scientist",
    image:
      "https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=400&h=400&fit=crop&crop=face",
    status: "online",
    tags: ["Science", "Hiking", "Photography"],
    about:
      "Science enthusiast seeking an intellectually stimulating relationship.",
  },
  {
    id: 6,
    name: "Arjun Mehta",
    age: 28,
    location: "Pune, Maharashtra",
    education: "MBA Marketing",
    profession: "Marketing Manager",
    image:
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face",
    status: "offline",
    tags: ["Creative", "Sports", "Adventure"],
    about:
      "Creative professional looking for someone who shares a zest for life.",
  },
];

const MatrimonialDashboard = () => {
  const [activeSection, setActiveSection] = useState("matches");
  const [profiles, setProfiles] = useState(sampleProfiles);
  const [filteredProfiles, setFilteredProfiles] = useState(sampleProfiles);
  const [searchFilters, setSearchFilters] = useState({
    ageRange: "",
    location: "",
    education: "",
    profession: "",
  });
  const [selectedProfile, setSelectedProfile] = useState(null);
  const [stats, setStats] = useState({
    totalProfiles: 1250,
    activeProfiles: 890,
    newMatches: 25,
    messages: 12,
  });

  useEffect(() => {
    const interval = setInterval(() => {
      setStats((prev) => ({
        ...prev,
        totalProfiles: prev.totalProfiles + Math.floor(Math.random() * 5),
        activeProfiles: prev.activeProfiles + Math.floor(Math.random() * 3),
        newMatches: prev.newMatches + Math.floor(Math.random() * 2),
        messages: prev.messages + Math.floor(Math.random() * 3),
      }));
    }, 10000);

    return () => clearInterval(interval);
  }, []);

  const handleFilterChange = (filterName, value) => {
    setSearchFilters((prev) => ({ ...prev, [filterName]: value }));
  };

  const applyFilters = () => {
    let filtered = sampleProfiles;

    if (searchFilters.location) {
      filtered = filtered.filter((profile) =>
        profile.location
          .toLowerCase()
          .includes(searchFilters.location.toLowerCase())
      );
    }

    if (searchFilters.education) {
      filtered = filtered.filter((profile) =>
        profile.education
          .toLowerCase()
          .includes(searchFilters.education.toLowerCase())
      );
    }

    if (searchFilters.profession) {
      filtered = filtered.filter((profile) =>
        profile.profession
          .toLowerCase()
          .includes(searchFilters.profession.toLowerCase())
      );
    }

    setFilteredProfiles(filtered);
  };

  const sidebarItems = [
    { id: "matches", label: "My Matches", icon: Heart },
    { id: "activity", label: "Activity", icon: Activity },
    { id: "messages", label: "Messages", icon: MessageCircle },
    // { id: "interests", label: "Interest Sent", icon: UserCheck },
    { id: "search", label: "Advanced Search", icon: Search },
    { id: "profile", label: "Profile", icon: User },
  ];

  const ProfileCard = ({ profile }) => (
    <div className="matrimonial-dashboard__profile-card">
      <div className="matrimonial-dashboard__profile-image-container">
        <img
          src={profile.image}
          alt={profile.name}
          className="matrimonial-dashboard__profile-image"
        />
        <span
          className={`matrimonial-dashboard__profile-status ${profile.status}`}
        >
          {profile.status}
        </span>
      </div>
      <div className="matrimonial-dashboard__profile-content">
        <h3 className="matrimonial-dashboard__profile-name">{profile.name}</h3>
        <div className="matrimonial-dashboard__profile-details">
          <p>
            <MapPin size={14} style={{ marginRight: "5px" }} />
            {profile.location}
          </p>
          <p>
            <Calendar size={14} style={{ marginRight: "5px" }} />
            {profile.age} years
          </p>
          <p>
            <User size={14} style={{ marginRight: "5px" }} />
            {profile.profession}
          </p>
        </div>
        <div className="matrimonial-dashboard__profile-tags">
          {profile.tags.map((tag, index) => (
            <span key={index} className="matrimonial-dashboard__profile-tag">
              {tag}
            </span>
          ))}
        </div>
        <div className="matrimonial-dashboard__profile-actions">
          <button
            className="matrimonial-dashboard__btn matrimonial-dashboard__btn-primary"
            onClick={() => setSelectedProfile(profile)}
          >
            <Heart size={16} />
            View Profile
          </button>
          <button className="matrimonial-dashboard__btn matrimonial-dashboard__btn-secondary">
            <MessageCircle size={16} />
            Message
          </button>
        </div>
      </div>
    </div>
  );

  const StatCard = ({ title, value, icon: Icon, change }) => (
    <div className="matrimonial-dashboard__stat-card">
      <div className="matrimonial-dashboard__stat-header">
        <span className="matrimonial-dashboard__stat-title">{title}</span>
        <div className="matrimonial-dashboard__stat-icon">
          <Icon size={20} />
        </div>
      </div>
      <div className="matrimonial-dashboard__stat-value">
        {value.toLocaleString()}
      </div>
      {change && (
        <div
          className={`matrimonial-dashboard__stat-change ${
            change > 0 ? "positive" : "negative"
          }`}
        >
          {change > 0 ? "+" : ""}
          {change}% from last week
        </div>
      )}
    </div>
  );

  const renderContent = () => {
    switch (activeSection) {
      case "matches":
        return (
          <Matches
            profiles={filteredProfiles}
            onSelectProfile={(p) => setSelectedProfile(p)}
          />
        );
      case "activity":
        return <ActivitySection />;
      case "messages":
        return <MessagesSection />;
      case "interests":
        return <InterestsSection />;
      case "search":
        return (
          <AdvancedSearchSection
            onApply={(filters) => {
              let result = sampleProfiles;
              if (filters.location) {
                result = result.filter((p) =>
                  p.location
                    .toLowerCase()
                    .includes(filters.location.toLowerCase())
                );
              }
              if (filters.education) {
                result = result.filter((p) =>
                  p.education
                    .toLowerCase()
                    .includes(filters.education.toLowerCase())
                );
              }
              if (filters.profession) {
                result = result.filter((p) =>
                  p.profession
                    .toLowerCase()
                    .includes(filters.profession.toLowerCase())
                );
              }
              if (filters.ageFrom || filters.ageTo) {
                result = result.filter(
                  (p) =>
                    p.age >= (Number(filters.ageFrom) || 0) &&
                    p.age <= (Number(filters.ageTo) || 200)
                );
              }
              setFilteredProfiles(result);
              setActiveSection("matches");
            }}
          />
        );
      case "profile":
        return <ProfileSection />;
      default:
        return (
          <Matches
            profiles={filteredProfiles}
            onSelectProfile={(p) => setSelectedProfile(p)}
          />
        );
    }
  };

  return (
    <div className="matrimonial-dashboard">
      <div className="matrimonial-dashboard__container">
        <aside className="matrimonial-dashboard__sidebar">
          <ul className="matrimonial-dashboard__sidebar-menu">
            {sidebarItems.map((item) => {
              const Icon = item.icon;
              return (
                <li key={item.id}>
                  <a
                    href="#"
                    className={`matrimonial-dashboard__sidebar-link ${
                      activeSection === item.id ? "active" : ""
                    }`}
                    onClick={(e) => {
                      e.preventDefault();
                      setActiveSection(item.id);
                    }}
                  >
                    <Icon size={20} />
                    {item.label}
                  </a>
                </li>
              );
            })}
          </ul>
        </aside>

        <main className="matrimonial-dashboard__main">{renderContent()}</main>
      </div>
    </div>
  );
};

export default MatrimonialDashboard;
