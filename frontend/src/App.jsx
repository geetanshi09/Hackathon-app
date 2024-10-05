/* eslint-disable no-unused-vars */
import { Button } from "./components/ui/button";
import { useEffect, useState } from "react";
import React from "react";
import "./App.css";
import { Routes, Route } from "react-router-dom";
import Home from "./pages/Home";

const App = () => {
 


  return (

    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/about" element={<h1>About</h1>} />
      <Route path="/services" element={<h1>Services</h1>} />
      <Route path="/contact" element={<h1>Contact</h1>} />
    </Routes>
  );
};

export default App;
