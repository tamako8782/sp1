const apiButton = document.getElementById("apiButton");
const clearButton = document.getElementById("clearButton");
const apiResponse = document.getElementById("apiResponse");
const apiIp = "APIIPADDRESS"


apiButton.addEventListener("click", () => {
    fetch(`http://${apiIp}:8080/testapi`)
        .then(response => response.json())
        .then(data => apiResponse.textContent = data.message);
});

clearButton.addEventListener("click", () => {
    apiResponse.textContent = "";
});