var express = require ("express");
let app = express();
app.use (express.static("landing"))

app.listen(2025,function(req,resp){
    console.log("Server Has Been Started :)");
})
//index
app.get("/",function(req,resp){
    let path=__dirname+"index.html";
    resp.sendFile(path);
})
//readme
const path = require("path");
app.get("/readme", function (req, resp) {
    const filePath = path.join(__dirname, "landing", "readme.html");
    resp.sendFile(filePath);
});

app.get("/app",function(req,resp){
    let path=__dirname+"/landing/app/auth/login/index.html";
    resp.sendFile(path);
})
