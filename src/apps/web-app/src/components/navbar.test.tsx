import { render, screen } from "@testing-library/react";
import { userEvent } from "@testing-library/user-event";
import NavBar from "@/components/navbar";

describe("NavBar", () => {
  test("renders the brand name", () => {
    render(<NavBar />);
    expect(screen.getByText("PUCVault")).toBeInTheDocument();
  });
  test("home link navigates to /", () => {
    render(<NavBar />);
    const link = screen.getByRole("link", { name: /home/i });
    expect(link.getAttribute("href")).toBe("/");
  });
  test("Popular link navigates to /popular", () => {
    render(<NavBar />);
    const link = screen.getByRole("link", { name: /popular/i });
    expect(link.getAttribute("href")).toBe("/popular");
  });
  test("All link navigates to /all", () => {
    render(<NavBar />);
    const link = screen.getByRole("link", { name: /popular/i });
    expect(link.getAttribute("href")).toBe("/popular");
  });
  test("search bar accepts user input", async () => {
    const user = userEvent.setup();
    render(<NavBar />);
    const input = screen.getByRole("searchbox");
    await user.type(input, "test");
    expect(input).toHaveValue("test");
  });
});
