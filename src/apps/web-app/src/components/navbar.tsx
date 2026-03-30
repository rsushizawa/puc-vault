import { useState } from "react";

export const TopNavBar = ({ activeLink = "Home" }) => {
  const [q, setQ] = useState("");
  return (
    <header
      style={{
        background: T.bg,
        height: 64,
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "0 24px",
        boxSizing: "border-box",
        position: "sticky",
        top: 0,
        zIndex: 50,
        width: "100%",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 32 }}>
        <span
          style={{
            fontSize: 20,
            fontWeight: 700,
            color: T.textPrimary,
            letterSpacing: "-0.5px",
            fontFamily: F,
          }}
        >
          PucVault
        </span>
        <nav style={{ display: "flex", gap: 24 }}>
          {["Home", "Popular", "All"].map((l) => (
            <a
              key={l}
              href="#"
              style={{
                fontSize: 16,
                color: T.textSecondary,
                textDecoration: "none",
                fontWeight: activeLink === l ? 600 : 400,
                fontFamily: F,
              }}
            >
              {l}
            </a>
          ))}
        </nav>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
        <div
          style={{
            background: T.surface,
            borderRadius: T.radius,
            display: "flex",
            alignItems: "center",
            gap: 8,
            padding: "6px 12px",
          }}
        >
          <Search size={14} />
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search communities..."
            style={{
              background: "none",
              border: "none",
              outline: "none",
              color: T.textDim,
              fontSize: 14,
              width: 220,
              fontFamily: F,
            }}
          />
        </div>
        <Bell size={16} /> <Grid size={16} />
        <Avatar size={32} initials="U" bg={T.surfaceHover} />
      </div>
    </header>
  );
};
