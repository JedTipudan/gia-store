package com.giastore.repository;

import com.giastore.model.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface MemberRepository extends JpaRepository<Member, Long> {
    List<Member> findByStatus(String status);
    List<Member> findByPaluwaganPackageId(Long packageId);
    List<Member> findByUserId(Long userId);
    Optional<Member> findByUserIdAndStatus(Long userId, String status);
}
