package dev.museonocturno;

import static org.junit.jupiter.api.Assertions.*;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "spring.datasource.url=jdbc:h2:mem:museum-test")
class MuseumApiTest {
    @LocalServerPort int port;
    private final ObjectMapper json = new ObjectMapper();
    private final HttpClient client = HttpClient.newHttpClient();

    @Test
    void createsReordersAndDeletesAnExhibition() throws Exception {
        var catalog = request("GET", "artworks", null);
        assertEquals(200, catalog.statusCode());
        var works = json.readTree(catalog.body());
        assertEquals(12, works.size());
        for (var work : works) {
            assertEquals("https", URI.create(work.get("imageUrl").asString()).getScheme());
            assertEquals("assets/met-" + work.get("id").asInt() + ".jpg",
                    work.get("imageAsset").asString());
        }
        assertEquals("Grabado", works.get(0).get("category").asString());
        assertFalse(works.get(0).get("observation").asString().isBlank());

        assertEquals(400, request("POST", "exhibitions",
                """
                {"title":"Sala inválida","artworkIds":[123]}
                """).statusCode());

        var created = request("POST", "exhibitions",
                """
                {"title":"Jardines","artworkIds":[436535,436528]}
                """);
        assertEquals(201, created.statusCode());
        String path = "exhibitions/" + json.readTree(created.body()).get("id").asString();
        assertEquals(200, request("PUT", path,
                """
                {"title":"Flores","artworkIds":[436528,436535]}
                """).statusCode());
        var listed = json.readTree(request("GET", "exhibitions", null).body()).get(0);
        assertEquals("Flores", listed.get("title").asString());
        assertEquals(436528, listed.get("artworkIds").get(0).asInt());
        assertEquals(204, request("DELETE", path, null).statusCode());
        assertTrue(json.readTree(request("GET", "exhibitions", null).body()).isEmpty());
        assertEquals(404, request("DELETE", path, null).statusCode());
    }

    private HttpResponse<String> request(String method, String path, String body) throws Exception {
        var builder = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + "/api/" + path));
        if (body != null) builder.header("Content-Type", "application/json");
        return client.send(builder.method(method, body == null ? HttpRequest.BodyPublishers.noBody()
                : HttpRequest.BodyPublishers.ofString(body)).build(), HttpResponse.BodyHandlers.ofString());
    }
}
