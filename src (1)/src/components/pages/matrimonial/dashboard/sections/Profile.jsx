import React from "react";

const Profile = ({ user }) => {
  const me = user || {
    profileFor: "Self",
    profileType: "Premium",
    name: "Tim Kook",
    showName: true,
    dob: "1996-07-15",
    motherTongue: "Hindi",
    religion: "Hindu",
    caste: "Brahmin",
    casteNoBar: false,
    manglik: "Non-Manglik",
    phone: "+91 9876543210",
    phoneVerified: true,
    familyType: "Nuclear",
    brothers: 1,
    marriedBrothers: 0,
    unmarriedBrothers: 1,
    sisters: 2,
    marriedSisters: 1,
    unmarriedSisters: 1,
    fatherOccupation: "Businessman",
    motherOccupation: "Homemaker",
    aboutYourself:
      "I am a fun-loving and caring person who believes in simple living and high thinking. Looking forward to sharing my life with someone special.",
    hobbies: "Photography, Traveling, Cooking",
    partnerExpectations:
      "Looking for a life partner who is caring, respectful, and has family values.",
    image:
      "https://plus.unsplash.com/premium_photo-1689568126014-06fea9d5d341?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D",
  };

  return (
    <div className="matrimonial-dashboard-profile-section container">
      <div className="card shadow-lg mb-5">
        <div className="header">My Profile</div>

        <div className="profile-info text-center">
          <img src={me.image} alt={me.name} className="profile-image" />
          <h2>{me.showName ? me.name : "Name Hidden"}</h2>
          <p className="text-muted mb-1">{me.profileType} Member</p>
          <p className="fw-bold">{me.profileFor}</p>
        </div>

        <div className="container">
          <h4 className="profile-section-title">Personal Information</h4>
          <div className="profile-details">
            <div className="detail-card">
              <h5>Date of Birth</h5>
              <p>{me.dob}</p>
            </div>
            <div className="detail-card">
              <h5>Mother Tongue</h5>
              <p>{me.motherTongue}</p>
            </div>
            <div className="detail-card">
              <h5>Religion</h5>
              <p>{me.religion}</p>
            </div>
            <div className="detail-card">
              <h5>Caste</h5>
              <p>
                {me.caste} {me.casteNoBar ? "(Caste No Bar)" : ""}
              </p>
            </div>
            <div className="detail-card">
              <h5>Manglik</h5>
              <p>{me.manglik}</p>
            </div>
            <div className="detail-card">
              <h5>Phone</h5>
              <p>
                {me.phone}{" "}
                {me.phoneVerified && (
                  <span className="badge bg-success">Verified</span>
                )}
              </p>
            </div>
          </div>

          <h4 className="profile-section-title">Family Information</h4>
          <div className="profile-details">
            <div className="detail-card">
              <h5>Family Type</h5>
              <p>{me.familyType}</p>
            </div>
            <div className="detail-card">
              <h5>Brothers</h5>
              <p>
                {me.brothers} Total | {me.marriedBrothers} Married |{" "}
                {me.unmarriedBrothers} Unmarried
              </p>
            </div>
            <div className="detail-card">
              <h5>Sisters</h5>
              <p>
                {me.sisters} Total | {me.marriedSisters} Married |{" "}
                {me.unmarriedSisters} Unmarried
              </p>
            </div>
            <div className="detail-card">
              <h5>Father's Occupation</h5>
              <p>{me.fatherOccupation}</p>
            </div>
            <div className="detail-card">
              <h5>Mother's Occupation</h5>
              <p>{me.motherOccupation}</p>
            </div>
          </div>

          <h4 className="profile-section-title">About Me</h4>
          <div className="detail-card">
            <p>{me.aboutYourself}</p>
          </div>

          <h4 className="profile-section-title">Hobbies</h4>
          <div className="detail-card">
            <p>{me.hobbies}</p>
          </div>

          <h4 className="profile-section-title">Partner Expectations</h4>
          <div className="detail-card">
            <p>{me.partnerExpectations}</p>
          </div>
          <div className="btn-group">
            <button className="btn-primary">Edit Profile</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Profile;
