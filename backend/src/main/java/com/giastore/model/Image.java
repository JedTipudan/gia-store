package com.giastore.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "images")
public class Image {
    @Id
    private String filename;

    @Column(nullable = false, columnDefinition = "LONGTEXT")
    private String base64Data;

    @Column(nullable = false)
    private String contentType = "image/jpeg";

    private LocalDateTime uploadedAt = LocalDateTime.now();
}
