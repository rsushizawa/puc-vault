"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Search, User, Menu, X } from "lucide-react";

const NavBar = () => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <nav className="flex items-center justify-between bg-surface-base h-[64px] px-6">
      <div className="flex gap-9">
        <span className="text-text-primary font-bold">PUCVault</span>
        <div className="flex text-text-secondary text-[16px] gap-6">
          <Link href={"/"}>Home</Link>
          <Link href={"/popular"}>Popular</Link>
          <Link href={"/all"}>All</Link>
        </div>
      </div>
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2 bg-surface-raised px-3 py-1.5 rounded-sm">
          <Search size={16} />
          <input type="search" placeholder="Search communities..." />
        </div>
        <div className="flex items-center justify-center rounded-full bg-surface-overlay size-8">
          <User size={16} />
        </div>
      </div>
    </nav>
  );
};

export default NavBar;
