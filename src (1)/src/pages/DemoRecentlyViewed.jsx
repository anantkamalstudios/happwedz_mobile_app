import React, { useEffect } from 'react';
import { trackView, saveSearchPreferences, trackWishlist } from '../services/localStorageService';
import { useNavigate } from 'react-router-dom';

/**
 * Demo page to populate test data
 * Visit this page once to add sample data, then go to homepage
 */
function DemoRecentlyViewed() {
  const navigate = useNavigate();

  useEffect(() => {
    // Add sample vendors to recently viewed
    const sampleVendors = [
      {
        id: 1,
        name: 'Grand Palace Banquet Hall',
        category: 'banquet-hall',
        type: 'venue',
        location: 'Mumbai',
        image: 'https://images.unsplash.com/photo-1519167758481-83f29da8c2b6?w=400',
        price_range: '₹50,000 - ₹1,00,000',
        slug: 'grand-palace-banquet-hall'
      },
      {
        id: 2,
        name: 'Pixel Perfect Photography',
        category: 'photographer',
        type: 'vendor',
        location: 'Delhi',
        image: 'https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=400',
        price_range: '₹30,000 - ₹75,000',
        slug: 'pixel-perfect-photography'
      },
      {
        id: 3,
        name: 'Elegant Decorators',
        category: 'decorator',
        type: 'vendor',
        location: 'Bangalore',
        image: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400',
        price_range: '₹40,000 - ₹90,000',
        slug: 'elegant-decorators'
      },
      {
        id: 4,
        name: 'Royal Garden Resort',
        category: 'resort',
        type: 'venue',
        location: 'Goa',
        image: 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=400',
        price_range: '₹2,00,000 - ₹5,00,000',
        slug: 'royal-garden-resort'
      },
      {
        id: 5,
        name: 'Mehendi Magic',
        category: 'mehendi-artist',
        type: 'vendor',
        location: 'Pune',
        image: 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=400',
        price_range: '₹5,000 - ₹15,000',
        slug: 'mehendi-magic'
      },
      {
        id: 6,
        name: 'Delicious Caterers',
        category: 'caterer',
        type: 'vendor',
        location: 'Mumbai',
        image: 'https://images.unsplash.com/photo-1555244162-803834f70033?w=400',
        price_range: '₹500 - ₹1,500 per plate',
        slug: 'delicious-caterers'
      }
    ];

    // Track each vendor with a delay
    sampleVendors.forEach((vendor, index) => {
      setTimeout(() => {
        trackView(vendor);
      }, index * 100);
    });

    // Add sample search preferences
    setTimeout(() => {
      saveSearchPreferences({
        location: 'Mumbai',
        category: 'venue',
        budget: '100000',
        guest_count: '200'
      });
    }, 700);

    // Add some wishlist actions
    setTimeout(() => {
      trackWishlist(1);
      trackWishlist(2);
    }, 800);

  }, []);

  const handleGoHome = () => {
    navigate('/');
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      padding: '40px 20px'
    }}>
      <div style={{
        background: 'white',
        borderRadius: '16px',
        padding: '60px 40px',
        maxWidth: '600px',
        textAlign: 'center',
        boxShadow: '0 20px 60px rgba(0,0,0,0.3)'
      }}>
        <div style={{
          fontSize: '64px',
          marginBottom: '20px'
        }}>
          ✅
        </div>
        
        <h1 style={{
          fontSize: '32px',
          color: '#2c3e50',
          marginBottom: '16px'
        }}>
          Demo Data Added!
        </h1>
        
        <p style={{
          fontSize: '18px',
          color: '#7f8c8d',
          marginBottom: '30px',
          lineHeight: '1.6'
        }}>
          Sample vendors have been added to your "Recently Viewed" list.
          <br />
          Go to the homepage to see the components in action!
        </p>

        <div style={{
          background: '#f8f9fa',
          padding: '20px',
          borderRadius: '8px',
          marginBottom: '30px',
          textAlign: 'left'
        }}>
          <h3 style={{ marginTop: 0, color: '#2c3e50' }}>What was added:</h3>
          <ul style={{ color: '#7f8c8d', lineHeight: '1.8' }}>
            <li>✅ 6 sample vendors to "Recently Viewed"</li>
            <li>✅ Sample search preferences (Mumbai, Venue, ₹1,00,000)</li>
            <li>✅ 2 wishlist actions</li>
            <li>✅ Activity stats updated</li>
          </ul>
        </div>

        <button
          onClick={handleGoHome}
          style={{
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white',
            border: 'none',
            padding: '16px 48px',
            borderRadius: '8px',
            fontSize: '18px',
            fontWeight: '600',
            cursor: 'pointer',
            transition: 'transform 0.2s',
            boxShadow: '0 4px 12px rgba(102, 126, 234, 0.4)'
          }}
          onMouseOver={(e) => e.target.style.transform = 'scale(1.05)'}
          onMouseOut={(e) => e.target.style.transform = 'scale(1)'}
        >
          Go to Homepage →
        </button>

        <p style={{
          marginTop: '30px',
          fontSize: '14px',
          color: '#95a5a6'
        }}>
          All data is stored in localStorage (no backend required)
        </p>
      </div>
    </div>
  );
}

export default DemoRecentlyViewed;
