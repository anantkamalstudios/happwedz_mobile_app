import React, { useState } from "react";
import {
  Search,
  Filter,
  MapPin,
  Calendar,
  GraduationCap,
  Briefcase,
  Heart,
  User,
  Star,
  Eye,
  MessageCircle,
  Sliders,
  X,
  ChevronDown,
  ChevronUp,
} from "lucide-react";

const SearchComponent = () => {
  const [expanded, setExpanded] = useState(true);
  const [savedSearches] = useState([
    "Doctor, Age 25-30, Mumbai",
    "Engineer, Age 28-32, Pune",
  ]);
  const [profiles] = useState([
    {
      id: 1,
      name: "Aarav Sharma",
      age: 28,
      profession: "Software Engineer",
      location: "Mumbai",
      education: "B.Tech",
    },
    {
      id: 2,
      name: "Priya Mehta",
      age: 26,
      profession: "Doctor",
      location: "Pune",
      education: "MBBS",
    },
  ]);

  return (
    <div className="matrimonial matrimonial-dashboard">
      {/* Sidebar */}
      <aside
        className={`matrimonial-sidebar ${expanded ? "expanded" : "collapsed"}`}
      >
        <div className="matrimonial-sidebar-header">
          <h2>
            <Filter size={20} /> Filters
          </h2>
          <button
            onClick={() => setExpanded(!expanded)}
            className="matrimonial-toggle-btn"
          >
            {expanded ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
          </button>
        </div>

        {expanded && (
          <div className="matrimonial-filters">
            <div className="matrimonial-filter-group">
              <label>
                <MapPin size={16} /> Location
              </label>
              <input type="text" placeholder="Enter city" />
            </div>

            <div className="matrimonial-filter-group">
              <label>
                <Calendar size={16} /> Age
              </label>
              <input type="number" placeholder="Min" />
              <input type="number" placeholder="Max" />
            </div>

            <div className="matrimonial-filter-group">
              <label>
                <GraduationCap size={16} /> Education
              </label>
              <select>
                <option>Any</option>
                <option>B.Tech</option>
                <option>MBA</option>
                <option>MBBS</option>
              </select>
            </div>

            <div className="matrimonial-filter-group">
              <label>
                <Briefcase size={16} /> Profession
              </label>
              <select>
                <option>Any</option>
                <option>Engineer</option>
                <option>Doctor</option>
                <option>Teacher</option>
              </select>
            </div>
          </div>
        )}

        <div className="matrimonial-saved-searches">
          <h3>
            <Star size={16} /> Saved Searches
          </h3>
          <ul>
            {savedSearches.map((item, i) => (
              <li key={i}>
                {item} <X size={14} />
              </li>
            ))}
          </ul>
        </div>
      </aside>

      {/* Profiles Section */}
      <main className="matrimonial-profiles">
        <div className="matrimonial-searchbar">
          <input type="text" placeholder="Search profiles..." />
          <button>
            <Search size={18} /> Search
          </button>
        </div>

        <div className="matrimonial-profile-list">
          {profiles.map((profile) => (
            <div key={profile.id} className="matrimonial-profile-card">
              <div className="matrimonial-profile-info">
                <h3>
                  {profile.name}, {profile.age}
                </h3>
                <p>
                  <Briefcase size={14} /> {profile.profession}
                </p>
                <p>
                  <MapPin size={14} /> {profile.location}
                </p>
                <p>
                  <GraduationCap size={14} /> {profile.education}
                </p>
              </div>
              <div className="matrimonial-profile-actions">
                <button>
                  <Heart size={16} /> Like
                </button>
                <button>
                  <MessageCircle size={16} /> Message
                </button>
                <button>
                  <Eye size={16} /> View
                </button>
              </div>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
};

export default SearchComponent;
