const express = require("express");
const { add } = require("@pucvault/utils"); // import here

const app = express();
const port = 5000;

app.get("/add", (req, res) => {
  const { a, b } = req.query;
  res.json({ result: add(Number(a), Number(b)) });
});

app.listen(port, () => {
  console.log(`API server running on http://localhost:${port}`);
});
