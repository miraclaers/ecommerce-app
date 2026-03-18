import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Authenticator, useAuthenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';
import Navbar from './components/Navbar';
import Products from './components/Products';
import Cart from './components/Cart';
import Orders from './components/Orders';
import { api } from './api';
import { CartProvider } from './CartContext';
import './App.css';

function AppContent({ showLogin, setShowLogin }) {
  const { user, signOut } = useAuthenticator((context) => [context.user]);

  useEffect(() => {
    if (user) {
      setShowLogin(false);
      const email = user.signInDetails?.loginId || user.username;
      const name = user.username;
      api.getProfile().catch(() => {
        api.createProfile(email, name)
          .catch((err) => console.error('Failed to create profile:', err));
      });
    }
  }, [user]);

  return (
    <CartProvider user={user}>
      <Router>
        <div className="App">
          <Navbar signOut={signOut} user={user} onSignInClick={() => setShowLogin(true)} />
          {showLogin && !user && (
            <div className="login-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowLogin(false); }}>
              <div className="login-modal">
                <Authenticator signUpAttributes={['email', 'name']} />
              </div>
            </div>
          )}
          <Routes>
            <Route path="/" element={<Products user={user} onSignInClick={() => setShowLogin(true)} />} />
            <Route path="/cart" element={<Cart user={user} onSignInClick={() => setShowLogin(true)} />} />
            <Route path="/orders" element={<Orders user={user} onSignInClick={() => setShowLogin(true)} />} />
          </Routes>
        </div>
      </Router>
    </CartProvider>
  );
}

function App() {
  const [showLogin, setShowLogin] = useState(false);

  return (
    <Authenticator.Provider>
      <AppContent showLogin={showLogin} setShowLogin={setShowLogin} />
    </Authenticator.Provider>
  );
}

export default App;
