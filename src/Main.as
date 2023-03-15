HttpResponse@ HandleGhostUpload(const string &in type, const string &in route, dictionary@ headers, const string &in data) {
    if (type != "POST") return HttpResponse(405, "Must be a POST request.");
    log_info("Route: " + route);
    log_info("Data length: " + data.Length);
    if (!route.ToLower().EndsWith(".ghost.gbx")) {
        return HttpResponse(404);
    }
    uint suffix = 0;
    while (IO::FileExists(ReplayPathWithSuffix(route, suffix))) {
        suffix++;
        if (suffix >= 100) throw("More than 100 replays with the same filename...");
    }
    auto fname = Net::UrlDecode(ReplayPathWithSuffix(route, suffix));
    string folderPath = GetFolderPath(fname);
    log_info("Saving ghost to: " + fname);
    if (!IO::FolderExists(folderPath)) {
        IO::CreateFolder(folderPath, true);
    }
    IO::File ghostFile(fname, IO::FileMode::Write);
    ghostFile.Write(data);
    ghostFile.Close();
    return HttpResponse(200, fname);
}

string ReplayPathWithSuffix(const string &in route, uint suffixCount) {
    string path = route;
    if (!path.StartsWith("/")) path = "/" + path;
    path = IO::FromUserGameFolder("Replays" + path);
    if (suffixCount > 0) {
        path += "_" + Text::Format("%02d", suffixCount);
    }
    return path;
}

// Note: must use `/` for final path delimeter.
string GetFolderPath(const string &in path) {
    auto parts = path.Split("/");
    if (parts.Length < 2) throw("Bad path for getting folder: " + path);
    parts.RemoveLast();
    return string::Join(parts, "/");
}

void Main() {
    sleep(100);
    auto server = HttpServer('0.0.0.0');
    @server.RequestHandler = HandleGhostUpload;
    server.StartServer();
    sleep(200);
    auto r = Net::HttpGet("http://localhost:29805/ghosts");
    while (!r.Finished()) yield();
    print("request status: " + r.ResponseCode());
    print("request got: " + r.String());
    print("request error: " + r.Error());
    print(FormatHeaders(r.ResponseHeaders()));
}
