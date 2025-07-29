var express = require ("express");
let app = express();
app.use (express.static("public"))
app.listen(2025,function(req,resp){
    console.log("Server Has Been Started :)");
})
//index
app.get("/",function(req,resp){
    let path=__dirname+"/public/index.html";
    resp.sendFile(path);
})
//readme
app.get("/readme",function(req,resp){
    let path=__dirname+"/public/readme.html";
    resp.sendFile(path);
})
app.get("/app",function(req,resp){
    let path=__dirname+"/public/app.html";
    resp.sendFile(path);
})