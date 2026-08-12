import {
  BarChart3,
  Calendar,
  Camera,
  Home,
  Menu,
  Music,
  Star,
  Users,
  Utensils,
  X,
} from "lucide-react";
import React from "react";

const ReviewsSidebar = ({
  isCollapsed,
  onToggle,
  activeSection,
  onSectionChange,
}) => {
  const menuItems = [
    { id: "reviews", label: "Reviews", icon: Star },
    { id: "review-collector", label: "Review Collector", icon: Home },
  ];

  return (
    <div className={`vendor-sidebar ${isCollapsed ? "collapsed" : ""}`}>
      <nav className="vendor-sidebar__nav">
        {menuItems.map((item) => {
          const IconComponent = item.icon;
          return (
            <button
              key={item.id}
              className={`vendor-sidebar__nav-item ${
                activeSection === item.id ? "active" : ""
              }`}
              onClick={() => onSectionChange(item.id)}
              title={isCollapsed ? item.label : ""}
            >
              <IconComponent size={20} />
              {!isCollapsed && <span>{item.label}</span>}
            </button>
          );
        })}
      </nav>
    </div>
  );
};

export default ReviewsSidebar;
