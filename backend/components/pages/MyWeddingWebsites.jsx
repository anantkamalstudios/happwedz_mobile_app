import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { FiPlus, FiEye, FiEdit, FiTrash2, FiShare, FiCalendar, FiHeart } from "react-icons/fi";
import Swal from "sweetalert2";

const MyWeddingWebsites = () => {
    const navigate = useNavigate();
    const [websites, setWebsites] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchUserWebsites();
    }, []);

    const fetchUserWebsites = async () => {
        try {
            const response = await fetch('/api/wedding-websites', {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('token')}`
                }
            });

            if (response.ok) {
                const data = await response.json();
                setWebsites(data);
            }
        } catch (error) {
            console.error('Error fetching websites:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Are you sure you want to delete this wedding website?')) {
            try {
                const response = await fetch(`/api/wedding-websites/${id}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${localStorage.getItem('token')}`
                    }
                });

                if (response.ok) {
                    setWebsites(websites.filter(website => website.id !== id));
                } else {
                    // alert('Failed to delete website');
                    Swal.fire({
                        icon:"error",
                        text:"Failed to delete website",
                        timer:1500
                    })
                }
            } catch (error) {
                console.error('Error deleting website:', error);
                // alert('Error deleting website');
                Swal.fire({
                  icon: "error",
                  text: "Error deleting website",
                  timer: 1500,
                });
            }
        }
    };

    const handlePublish = async (id) => {
        try {
            const response = await fetch(`/api/wedding-websites/${id}/publish`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('token')}`
                }
            });

            if (response.ok) {
                const result = await response.json();
                setWebsites(websites.map(website =>
                    website.id === id ? { ...website, isPublished: true, websiteUrl: result.websiteUrl } : website
                ));
                // alert('Website published successfully!');
                Swal.fire({
                    icon:"success",
                    text:"Website published successfully!",
                    timer:1500
                })
            } else {
                // alert('Failed to publish website');
                Swal.fire({
                    icon:"error",
                    text:"Failed to publish website",
                    timer:1500
                })
            }
        } catch (error) {
            console.error('Error publishing website:', error);
            // alert('Error publishing website');
            Swal.fire({
                icon:"error",
                text:"Error publishing website",
                timer:1500
            })
        }
    };

    if (loading) {
        return (
            <div className="d-flex justify-content-center align-items-center min-vh-100">
                <div className="spinner-border text-primary" role="status">
                    <span className="visually-hidden">Loading...</span>
                </div>
            </div>
        );
    }

    return (
        <div className="my-wedding-websites">
            <style>{`
                .my-wedding-websites {
                    background: linear-gradient(135deg, #fdfbfb 0%, #f8f4f1 100%);
                    min-height: 100vh;
                    padding: 40px 0;
                }
                
                .websites-header {
                    background: white;
                    border-radius: 20px;
                    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
                    padding: 40px;
                    margin-bottom: 30px;
                    text-align: center;
                }
                
                .header-title {
                    font-size: 2.5rem;
                    font-weight: 700;
                    color: #2d2d2d;
                    margin-bottom: 15px;
                    font-family: 'Georgia', serif;
                }
                
                .header-subtitle {
                    font-size: 1.1rem;
                    color: #666;
                    margin-bottom: 30px;
                }
                
                .create-btn {
                    background: linear-gradient(135deg, #ff6b9d 0%, #e91e63 100%);
                    border: none;
                    border-radius: 25px;
                    padding: 12px 30px;
                    color: white;
                    font-weight: 600;
                    font-size: 1.1rem;
                    transition: all 0.3s ease;
                    display: inline-flex;
                    align-items: center;
                    gap: 10px;
                }
                
                .create-btn:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 5px 15px rgba(255, 107, 157, 0.4);
                    color: white;
                }
                
                .websites-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
                    gap: 30px;
                }
                
                .website-card {
                    background: white;
                    border-radius: 20px;
                    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
                    overflow: hidden;
                    transition: all 0.3s ease;
                }
                
                .website-card:hover {
                    transform: translateY(-5px);
                    box-shadow: 0 15px 50px rgba(0, 0, 0, 0.15);
                }
                
                .card-image {
                    height: 200px;
                    background: linear-gradient(135deg, #ff6b9d 0%, #e91e63 100%);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    color: white;
                    font-size: 3rem;
                }
                
                .card-content {
                    padding: 25px;
                }
                
                .card-title {
                    font-size: 1.3rem;
                    font-weight: 600;
                    color: #2d2d2d;
                    margin-bottom: 10px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                }
                
                .card-date {
                    color: #666;
                    font-size: 0.9rem;
                    margin-bottom: 15px;
                    display: flex;
                    align-items: center;
                    gap: 5px;
                }
                
                .card-status {
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    margin-bottom: 20px;
                }
                
                .status-badge {
                    padding: 4px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: 600;
                }
                
                .status-published {
                    background: #d4edda;
                    color: #155724;
                }
                
                .status-draft {
                    background: #fff3cd;
                    color: #856404;
                }
                
                .card-actions {
                    display: flex;
                    gap: 8px;
                    flex-wrap: wrap;
                }
                
                .action-btn {
                    border: none;
                    border-radius: 15px;
                    padding: 8px 12px;
                    font-size: 0.9rem;
                    font-weight: 600;
                    transition: all 0.3s ease;
                    display: flex;
                    align-items: center;
                    gap: 5px;
                }
                
                .btn-primary-action {
                    background: #007bff;
                    color: white;
                }
                
                .btn-primary-action:hover {
                    background: #0056b3;
                    transform: translateY(-1px);
                }
                
                .btn-success-action {
                    background: #28a745;
                    color: white;
                }
                
                .btn-success-action:hover {
                    background: #1e7e34;
                    transform: translateY(-1px);
                }
                
                .btn-danger-action {
                    background: #dc3545;
                    color: white;
                }
                
                .btn-danger-action:hover {
                    background: #c82333;
                    transform: translateY(-1px);
                }
                
                .btn-secondary-action {
                    background: #6c757d;
                    color: white;
                }
                
                .btn-secondary-action:hover {
                    background: #545b62;
                    transform: translateY(-1px);
                }
                
                .empty-state {
                    text-align: center;
                    padding: 60px 20px;
                    background: white;
                    border-radius: 20px;
                    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
                }
                
                .empty-icon {
                    font-size: 4rem;
                    color: #ddd;
                    margin-bottom: 20px;
                }
                
                .empty-title {
                    font-size: 1.5rem;
                    color: #666;
                    margin-bottom: 10px;
                }
                
                .empty-subtitle {
                    color: #999;
                    margin-bottom: 30px;
                }
                
                @media (max-width: 768px) {
                    .websites-grid {
                        grid-template-columns: 1fr;
                    }
                    
                    .header-title {
                        font-size: 2rem;
                    }
                    
                    .card-actions {
                        flex-direction: column;
                    }
                }
            `}</style>

            <div className="container">
                <div className="websites-header">
                    <h1 className="header-title">My Wedding Websites</h1>
                    <p className="header-subtitle">Manage and share your beautiful wedding websites</p>
                    <button
                        className="create-btn"
                        onClick={() => navigate('/choose-template')}
                    >
                        <FiPlus /> Create New Website
                    </button>
                </div>

                {websites.length === 0 ? (
                    <div className="empty-state">
                        <FiHeart className="empty-icon" />
                        <h3 className="empty-title">No wedding websites yet</h3>
                        <p className="empty-subtitle">Create your first wedding website to get started</p>
                        <button
                            className="create-btn"
                            onClick={() => navigate('/choose-template')}
                        >
                            <FiPlus /> Create Your First Website
                        </button>
                    </div>
                ) : (
                    <div className="websites-grid">
                        {websites.map(website => (
                            <div key={website.id} className="website-card">
                                <div className="card-image">
                                    <FiHeart />
                                </div>
                                <div className="card-content">
                                    <h3 className="card-title">
                                        <FiHeart />
                                        {website.brideName} & {website.groomName}
                                    </h3>
                                    <div className="card-date">
                                        <FiCalendar />
                                        {new Date(website.weddingDate).toLocaleDateString()}
                                    </div>
                                    <div className="card-status">
                                        <span className={`status-badge ${website.isPublished ? 'status-published' : 'status-draft'}`}>
                                            {website.isPublished ? 'Published' : 'Draft'}
                                        </span>
                                    </div>
                                    <div className="card-actions">
                                        <button
                                            className="action-btn btn-primary-action"
                                            onClick={() => navigate(`/wedding-website/${website.id}`)}
                                        >
                                            <FiEye /> View
                                        </button>
                                        <button
                                            className="action-btn btn-secondary-action"
                                            onClick={() => navigate(`/wedding-form/${website.templateId}?edit=${website.id}`)}
                                        >
                                            <FiEdit /> Edit
                                        </button>
                                        {!website.isPublished ? (
                                            <button
                                                className="action-btn btn-success-action"
                                                onClick={() => handlePublish(website.id)}
                                            >
                                                <FiShare /> Publish
                                            </button>
                                        ) : (
                                            <button
                                                className="action-btn btn-success-action"
                                                onClick={() => {
                                                    navigator.clipboard.writeText(`${window.location.origin}/api/wedding/${website.websiteUrl}`);
                                                    // alert('Website link copied to clipboard!');
                                                    Swal.fire({
                                                        text:"Website link copied to clipboard!",
                                                        timer:1500
                                                    })
                                                }}
                                            >
                                                <FiShare /> Share
                                            </button>
                                        )}
                                        <button
                                            className="action-btn btn-danger-action"
                                            onClick={() => handleDelete(website.id)}
                                        >
                                            <FiTrash2 /> Delete
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

export default MyWeddingWebsites;
