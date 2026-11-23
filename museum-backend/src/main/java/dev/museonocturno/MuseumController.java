package dev.museonocturno;

import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = {"http://localhost:7357", "http://127.0.0.1:7357"})
public class MuseumController {
    record Artwork(int id, String title, String artist, String period, String imageUrl, String sourceUrl) {}
    record Exhibition(String id, String title, List<Integer> artworkIds) {}
    record Draft(String title, List<Integer> artworkIds) {}

    private final JdbcTemplate db;
    private final List<Artwork> catalog;
    private final Set<Integer> artworkIds;

    MuseumController(JdbcTemplate db, ObjectMapper json) throws IOException {
        this.db = db;
        try (var source = new ClassPathResource("artworks.json").getInputStream()) {
            catalog = json.readValue(source, new TypeReference<List<Artwork>>() {});
        }
        artworkIds = catalog.stream().map(Artwork::id).collect(Collectors.toUnmodifiableSet());
    }

    @GetMapping("/artworks")
    List<Artwork> artworks() {
        return catalog;
    }

    @GetMapping("/exhibitions")
    List<Exhibition> exhibitions() {
        return db.query("select id, title, artwork_ids from exhibitions order by title, id",
                (row, index) -> new Exhibition(row.getString("id"), row.getString("title"),
                    Arrays.stream(row.getString("artwork_ids").split(",")).map(Integer::valueOf).toList()));
    }

    @PostMapping("/exhibitions")
    @ResponseStatus(HttpStatus.CREATED)
    Exhibition create(@RequestBody Draft draft) {
        var exhibition = validate(UUID.randomUUID().toString(), draft);
        db.update("insert into exhibitions (id, title, artwork_ids) values (?, ?, ?)",
                exhibition.id(), exhibition.title(), ids(exhibition));
        return exhibition;
    }

    @PutMapping("/exhibitions/{id}")
    Exhibition update(@PathVariable UUID id, @RequestBody Draft draft) {
        var exhibition = validate(id.toString(), draft);
        requireFound(db.update("update exhibitions set title = ?, artwork_ids = ? where id = ?",
                exhibition.title(), ids(exhibition), exhibition.id()));
        return exhibition;
    }

    @DeleteMapping("/exhibitions/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void delete(@PathVariable UUID id) {
        requireFound(db.update("delete from exhibitions where id = ?", id.toString()));
    }

    private Exhibition validate(String id, Draft draft) {
        String title = draft.title() == null ? "" : draft.title().strip();
        var ids = draft.artworkIds();
        if (title.isEmpty() || title.length() > 100 || ids == null || ids.isEmpty()
                || ids.size() > 30 || ids.stream().anyMatch(value -> value == null || !artworkIds.contains(value))
                || new HashSet<>(ids).size() != ids.size()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid title or artwork selection");
        }
        return new Exhibition(id, title, ids);
    }

    private static String ids(Exhibition exhibition) {
        return exhibition.artworkIds().stream().map(String::valueOf).collect(Collectors.joining(","));
    }

    private static void requireFound(int rows) {
        if (rows == 0) throw new ResponseStatusException(HttpStatus.NOT_FOUND);
    }
}
