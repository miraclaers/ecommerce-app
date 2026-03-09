import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Authenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';
import Navbar from './components/Navbar';
import Products from './components/Products';
import Cart from './components/Cart';
import Orders from './components/Orders';
import { api } from './api';
import './App.css';

// Component to handle profile creation
function AppContent({ signOut, user }) {
  useEffect(() => {
    if (user) {
      const email = user.signInDetails?.loginId || user.username;
      const name = user.username;
      
      // Check if profile exists, create only if it doesn't
      api.getProfile().catch((error) => {
        console.log('Profile not found, creating...', { email, name });
        // Profile doesn't exist, create it
        api.createProfile(email, name)
          .then(() => console.log('Profile created successfully'))
          .catch((err) => {
            console.error('Failed to create profile:', err);
          });
      });
    }
  }, [user]);

  return (
    <Router>
      <div className="App">
        <Navbar signOut={signOut} user={user} />
        <Routes>
          <Route path="/" element={<Products />} />
          <Route path="/cart" element={<Cart />} />
          <Route path="/orders" element={<Orders />} />
        </Routes>
      </div>
    </Router>
  );
}

function App() {
  return (
    <Authenticator
      signUpAttributes={['email', 'name']}
      components={{
        SignUp: {
          FormFields() {
            return (
              <>
                <Authenticator.SignUp.FormFields />
              </>
            );
          },
        },
      }}
    >
      {({ signOut, user }) => (
        <AppContent signOut={signOut} user={user} />
      )}
    </Authenticator>
  );
}

export default App;
