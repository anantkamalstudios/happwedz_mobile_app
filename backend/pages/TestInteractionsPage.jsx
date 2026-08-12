import React, { useState } from 'react';
import { useSelector } from 'react-redux';
import RecentlyViewed from '../components/common/RecentlyViewed';
import ContinueSection from '../components/common/ContinueSection';
import { useManualTrack } from '../hooks/useTrackInteraction';
import { trackInteraction } from '../services/interactionService';

function TestInteractionsPage() {
  const { user } = useSelector((state) => state.auth);
  const track = useManualTrack();
  const [testResult, setTestResult] = useState('');

  const testTrackView = async () => {
    try {
      if (!user?.id) {
        setTestResult('❌ Please login first!');
        return;
      }

      const result = await trackInteraction({
        user_id: user.id,
        vendor_subcategory_data_id: 97665,
        action: 'view',
        value: {
          vendor_type: 'venue',
          category: 'banquet-hall',
          name: 'Test Venue',
          location: 'Mumbai',
          price_range: '50000-100000'
        }
      });

      setTestResult('✅ View tracked successfully! ' + JSON.stringify(result));
    } catch (error) {
      setTestResult('❌ Error: ' + error.message);
    }
  };

  const testTrackClick = async () => {
    try {
      if (!user?.id) {
        setTestResult('❌ Please login first!');
        return;
      }

      track(98342, 'click', {
        vendor_type: 'vendor',
        category: 'photographer',
        name: 'Test Photographer',
        location: 'Delhi'
      });

      setTestResult('✅ Click tracked successfully!');
    } catch (error) {
      setTestResult('❌ Error: ' + error.message);
    }
  };

  return (
    <div style={{ padding: '40px', maxWidth: '1400px', margin: '0 auto' }}>
      <h1 style={{ textAlign: 'center', marginBottom: '30px' }}>
        🧪 Test Interactions & Recently Viewed
      </h1>

      {/* User Status */}
      <div style={{ 
        background: user?.id ? '#d4edda' : '#f8d7da', 
        padding: '20px', 
        borderRadius: '8px',
        marginBottom: '30px',
        textAlign: 'center'
      }}>
        {user?.id ? (
          <div>
            <h3 style={{ margin: 0, color: '#155724' }}>
              ✅ Logged in as: {user.name || user.email || `User #${user.id}`}
            </h3>
            <p style={{ margin: '8px 0 0 0', color: '#155724' }}>
              User ID: {user.id}
            </p>
          </div>
        ) : (
          <div>
            <h3 style={{ margin: 0, color: '#721c24' }}>
              ❌ Not logged in
            </h3>
            <p style={{ margin: '8px 0 0 0', color: '#721c24' }}>
              Please login to test the features
            </p>
          </div>
        )}
      </div>

      {/* Test Buttons */}
      <div style={{ 
        background: '#f8f9fa', 
        padding: '30px', 
        borderRadius: '12px',
        marginBottom: '40px'
      }}>
        <h2 style={{ marginTop: 0 }}>Test Tracking</h2>
        <div style={{ display: 'flex', gap: '16px', marginBottom: '20px' }}>
          <button
            onClick={testTrackView}
            style={{
              padding: '12px 24px',
              background: '#007bff',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
              fontSize: '16px',
              fontWeight: '600'
            }}
          >
            Track View
          </button>
          <button
            onClick={testTrackClick}
            style={{
              padding: '12px 24px',
              background: '#28a745',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
              fontSize: '16px',
              fontWeight: '600'
            }}
          >
            Track Click
          </button>
        </div>
        {testResult && (
          <div style={{
            padding: '16px',
            background: testResult.startsWith('✅') ? '#d4edda' : '#f8d7da',
            color: testResult.startsWith('✅') ? '#155724' : '#721c24',
            borderRadius: '8px',
            marginTop: '16px',
            wordBreak: 'break-word'
          }}>
            {testResult}
          </div>
        )}
      </div>

      <hr style={{ margin: '40px 0', border: 'none', borderTop: '2px solid #dee2e6' }} />

      {/* Continue Section */}
      <div style={{ marginBottom: '40px' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '20px' }}>
          Continue Where You Left Off Component
        </h2>
        <ContinueSection />
      </div>

      <hr style={{ margin: '40px 0', border: 'none', borderTop: '2px solid #dee2e6' }} />

      {/* Recently Viewed */}
      <div>
        <h2 style={{ textAlign: 'center', marginBottom: '20px' }}>
          Recently Viewed Component
        </h2>
        <RecentlyViewed limit={6} showTitle={true} />
      </div>

      {/* Instructions */}
      <div style={{
        background: '#fff3cd',
        padding: '20px',
        borderRadius: '8px',
        marginTop: '40px'
      }}>
        <h3 style={{ marginTop: 0, color: '#856404' }}>📝 Testing Instructions:</h3>
        <ol style={{ color: '#856404', lineHeight: '1.8' }}>
          <li>Make sure you're logged in</li>
          <li>Click "Track View" and "Track Click" buttons above</li>
          <li>Refresh the page to see the components update</li>
          <li>The "Recently Viewed" section should show the tracked items</li>
          <li>The "Continue Section" should show your activity stats</li>
        </ol>
      </div>
    </div>
  );
}

export default TestInteractionsPage;
