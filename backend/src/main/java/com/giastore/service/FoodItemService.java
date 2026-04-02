package com.giastore.service;

import com.giastore.model.FoodItem;
import com.giastore.repository.FoodItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class FoodItemService {

    private final FoodItemRepository repo;

    public List<FoodItem> getAll() { return repo.findByActiveTrue(); }
    public List<FoodItem> getTodaysMenu() { return repo.findByActiveTrueAndAvailableTodayTrue(); }

    public FoodItem getById(Long id) {
        return repo.findById(id).orElseThrow(() -> new RuntimeException("Food item not found"));
    }

    public FoodItem save(FoodItem item) { return repo.save(item); }

    public FoodItem update(Long id, FoodItem updated) {
        FoodItem existing = getById(id);
        existing.setName(updated.getName());
        existing.setDescription(updated.getDescription());
        existing.setCategory(updated.getCategory());
        existing.setPrice(updated.getPrice());
        existing.setStock(updated.getStock());
        existing.setImageUrl(updated.getImageUrl());
        existing.setActive(updated.getActive());
        existing.setAvailableToday(updated.getAvailableToday());
        return repo.save(existing);
    }

    public FoodItem toggleToday(Long id) {
        FoodItem item = getById(id);
        item.setAvailableToday(!item.getAvailableToday());
        return repo.save(item);
    }

    // Hard delete — actually removes from DB
    public void delete(Long id) {
        repo.deleteById(id);
    }
}
