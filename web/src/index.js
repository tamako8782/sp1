const apiButton = document.getElementById("apiButton");
const clearButton = document.getElementById("clearButton");
const apiResponse = document.getElementById("apiResponse");

apiButton.addEventListener("click", () => {
    fetch("http://localhost:8080/testapi")
        .then(response => response.json())
        .then(data => apiResponse.textContent = data.message);
});

clearButton.addEventListener("click", () => {
    apiResponse.textContent = "";
});