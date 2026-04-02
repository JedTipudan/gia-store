package com.giastore.repository;

import com.giastore.model.PaluwaganPackage;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface PaluwaganPackageRepository extends JpaRepository<PaluwaganPackage, Long> {
    List<PaluwaganPackage> findByActiveTrue();
}
