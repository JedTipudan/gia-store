package com.giastore.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.File;
import java.io.IOException;
import java.nio.file.*;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
public class UploadController {

    private static final String UPLOAD_DIR = System.getProperty("user.home") + "/uploads/";

    @PostMapping("/image")
    public ResponseEntity<?> uploadImage(@RequestParam("file") MultipartFile file) throws IOException {
        File dir = new File(UPLOAD_DIR);
        if (!dir.exists()) dir.mkdirs();

        String ext = getExtension(file.getOriginalFilename());
        String filename = UUID.randomUUID() + "." + ext;
        Path path = Paths.get(UPLOAD_DIR + filename);
        Files.write(path, file.getBytes());

        String url = "/api/upload/images/" + filename;
        return ResponseEntity.ok(Map.of("url", url, "filename", filename));
    }

    @GetMapping("/images/{filename}")
    public ResponseEntity<byte[]> getImage(@PathVariable String filename) throws IOException {
        Path path = Paths.get(UPLOAD_DIR + filename);
        if (!Files.exists(path)) return ResponseEntity.notFound().build();
        byte[] bytes = Files.readAllBytes(path);
        String contentType = filename.endsWith(".png") ? "image/png" : "image/jpeg";
        return ResponseEntity.ok().header("Content-Type", contentType).body(bytes);
    }

    private String getExtension(String filename) {
        if (filename == null) return "jpg";
        int dot = filename.lastIndexOf('.');
        return dot >= 0 ? filename.substring(dot + 1).toLowerCase() : "jpg";
    }
}
