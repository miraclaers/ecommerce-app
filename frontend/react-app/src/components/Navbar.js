import React from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../CartContext';
import logo from '../assets/logo.svg';
import './Navbar.css';

function Navbar({ signOut, user, onSignInClick }) {
  const displayName = user?.signInDetails?.loginId || user?.username || 'User';
  const { cartCount } = useCart();
  
  return (
    <nav className="navbar">
      <div className="nav-brand">
        <Link to="/" className="brand-link">
          <img src={logo} alt="eCommerce Logo" className="logo" />
          <span>eCommerce Store</span>
        </Link>
      </div>
      <div className="nav-center">
        <Link to="/">Products</Link>
        <Link to="/cart" className="cart-link">
          🛒 Cart
          {cartCount > 0 && <span className="cart-badge">{cartCount}</span>}
        </Link>
        <Link to="/orders">📦 Orders</Link>
      </div>
      <div className="nav-right">
        <a 
          href="https://www.awswithchetan.com" 
          target="_blank" 
          rel="noopener noreferrer"
          className="website-link"
        >
          🌐 awswithchetan.com
        </a>
        {user ? (
          <div className="user-info">
            <span className="user-name">{displayName}</span>
            <button onClick={signOut} className="signout-btn">Sign Out</button>
          </div>
        ) : (
          <button onClick={onSignInClick} className="signout-btn">Sign In</button>
        )}
      </div>
    </nav>
  );
}

export default Navbar;
