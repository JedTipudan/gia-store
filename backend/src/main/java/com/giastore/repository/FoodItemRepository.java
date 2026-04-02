package com.giastore.repository;

import com.giastore.model.FoodItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FoodItemRepository extends JpaRepository<FoodItem, Long> {
    List<FoodItem> findByActiveTrue();
    List<FoodItem> findByActiveTrueAndAvailableTodayTrue();
    List<FoodItem> findByCategoryAndActiveTrue(String category);
}
