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

function AppContent() {
  const { user, signOut } = useAuthenticator((context) => [context.user]);

  useEffect(() => {
    if (user) {
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
          <Navbar signOut={signOut} user={user} />
          <Routes>
            <Route path="/" element={<Products user={user} />} />
            <Route path="/cart" element={<Cart user={user} />} />
            <Route path="/orders" element={<Orders user={user} />} />
          </Routes>
        </div>
      </Router>
    </CartProvider>
  );
}

function App() {
  return (
    <Authenticator.Provider>
      <AppContent />
    </Authenticator.Provider>
  );
}

export default App;
