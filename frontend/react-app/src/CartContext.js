import React, { createContext, useState, useContext, useEffect } from 'react';
import { api } from './api';

const CartContext = createContext();

export const useCart = () => useContext(CartContext);

export const CartProvider = ({ children, user }) => {
  const [cartCount, setCartCount] = useState(0);

  const refreshCartCount = () => {
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
  };

  useEffect(() => {
    refreshCartCount();
  }, [user]);

  return (
    <CartContext.Provider value={{ cartCount, refreshCartCount }}>
      {children}
    </CartContext.Provider>
  );
};
