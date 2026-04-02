package com.giastore.controller;

import com.giastore.model.FoodItem;
import com.giastore.service.FoodItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/food-items")
@RequiredArgsConstructor
public class FoodItemController {

    private final FoodItemService service;

    @GetMapping
    public List<FoodItem> getAll() { return service.getAll(); }

    @GetMapping("/today")
    public List<FoodItem> getToday() { return service.getTodaysMenu(); }

    @GetMapping("/{id}")
    public FoodItem getById(@PathVariable Long id) { return service.getById(id); }

    @PostMapping
    public FoodItem create(@RequestBody FoodItem item) { return service.save(item); }

    @PutMapping("/{id}")
    public FoodItem update(@PathVariable Long id, @RequestBody FoodItem item) {
        return service.update(id, item);
    }

    @PatchMapping("/{id}/toggle-today")
    public FoodItem toggleToday(@PathVariable Long id) { return service.toggleToday(id); }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.ok().build();
    }
}
