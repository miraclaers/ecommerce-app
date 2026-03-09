import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import './Navbar.css';

function Navbar({ signOut, user }) {
  const displayName = user?.signInDetails?.loginId || user?.username || 'User';
  const [cartCount, setCartCount] = useState(0);
  
  // Fetch cart count when user is logged in
  useEffect(() => {
    if (user) {
      api.getCart()
        .then(cart => {
          const count = cart.items?.reduce((sum, item) => sum + item.quantity, 0) || 0;
          setCartCount(count);
        })
        .catch(() => setCartCount(0));
    } else {
      setCartCount(0);
    }
  }, [user]);
  
  return (
    <nav className="navbar">
      <div className="nav-brand">
        <Link to="/">eCommerce Store</Link>
      </div>
      <div className="nav-links">
        <Link to="/">Products</Link>
        <Link to="/cart" className="cart-link">
          Cart
          {cartCount > 0 && <span className="cart-badge">{cartCount}</span>}
        </Link>
        <Link to="/orders">Orders</Link>
        {user && (
          <div className="user-info">
            <span className="user-name">{displayName}</span>
            <button onClick={signOut} className="signout-btn">Sign Out</button>
          </div>
        )}
      </div>
    </nav>
  );
}

export default Navbar;
