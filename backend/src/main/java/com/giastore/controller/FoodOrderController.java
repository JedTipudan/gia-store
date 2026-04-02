package com.giastore.controller;

import com.giastore.model.*;
import com.giastore.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class FoodOrderController {

    private final FoodOrderRepository orderRepo;
    private final FoodItemRepository foodItemRepo;
    private final UserRepository userRepository;

    @GetMapping("/user/{userId}")
    public List<FoodOrder> getByUser(@PathVariable Long userId) {
        return orderRepo.findByUserIdOrderByOrderedAtDesc(userId);
    }

    @GetMapping
    public List<FoodOrder> getAll() {
        return orderRepo.findAllByOrderByOrderedAtDesc();
    }

    @PostMapping
    public ResponseEntity<?> placeOrder(@RequestBody Map<String, Object> body) {
        Long userId = Long.valueOf(body.get("userId").toString());
        Long foodItemId = Long.valueOf(body.get("foodItemId").toString());
        int quantity = Integer.parseInt(body.getOrDefault("quantity", 1).toString());
        String note = body.getOrDefault("note", "").toString();

        FoodItem item = foodItemRepo.findById(foodItemId)
                .orElseThrow(() -> new RuntimeException("Food item not found"));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        FoodOrder order = new FoodOrder();
        order.setUser(user);
        order.setFoodItem(item);
        order.setQuantity(quantity);
        order.setTotalPrice(item.getPrice().multiply(BigDecimal.valueOf(quantity)));
        order.setNote(note);
        order.setStatus("PENDING");

        return ResponseEntity.ok(orderRepo.save(order));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        FoodOrder order = orderRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        order.setStatus(body.get("status"));
        return ResponseEntity.ok(orderRepo.save(order));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        orderRepo.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
