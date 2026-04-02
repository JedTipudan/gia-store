package com.giastore.controller;

import com.giastore.model.Image;
import com.giastore.repository.ImageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
@RequiredArgsConstructor
public class UploadController {

    private final ImageRepository imageRepository;

    @PostMapping("/image")
    public ResponseEntity<?> uploadImage(@RequestParam("file") MultipartFile file) throws IOException {
        String ext = getExtension(file.getOriginalFilename());
        String filename = UUID.randomUUID() + "." + ext;
        String contentType = file.getContentType() != null ? file.getContentType() : "image/jpeg";

        // Store as Base64 in DB — survives Railway redeploys
        String base64 = Base64.getEncoder().encodeToString(file.getBytes());

        Image image = new Image();
        image.setFilename(filename);
        image.setBase64Data(base64);
        image.setContentType(contentType);
        imageRepository.save(image);

        String url = "/api/upload/images/" + filename;
        return ResponseEntity.ok(Map.of("url", url, "filename", filename));
    }

    @GetMapping("/images/{filename}")
    public ResponseEntity<byte[]> getImage(@PathVariable String filename) {
        return imageRepository.findById(filename)
                .map(img -> {
                    byte[] bytes = Base64.getDecoder().decode(img.getBase64Data());
                    return ResponseEntity.ok()
                            .header(HttpHeaders.CONTENT_TYPE, img.getContentType())
                            .header(HttpHeaders.CACHE_CONTROL, "max-age=86400")
                            .body(bytes);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    private String getExtension(String filename) {
        if (filename == null) return "jpg";
        int dot = filename.lastIndexOf('.');
        return dot >= 0 ? filename.substring(dot + 1).toLowerCase() : "jpg";
    }
}
