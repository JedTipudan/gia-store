package com.giastore.repository;

import com.giastore.model.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MemberRepository extends JpaRepository<Member, Long> {
    List<Member> findByStatus(String status);
    List<Member> findByPaluwaganPackageId(Long packageId);
}
